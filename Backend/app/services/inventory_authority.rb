# frozen_string_literal: true

require "securerandom"

class InventoryAuthority
  class InventoryError < StandardError; end

  class << self
    def warehouse_inventory
      Item.order(:name, :sku).map(&:warehouse_payload)
    end

    def machine_inventory
      Machine.order(:name, :id).each_with_object({}) do |machine, result|
        rows = machine.machine_inventories.joins(:item).includes(:item).order("items.name ASC, items.sku ASC")
        result[machine.id] = rows.map do |row|
          {
            "sku" => row.item.sku,
            "name" => row.item.name,
            "qty" => row.quantity,
            "barcode" => row.item.barcode.to_s
          }
        end
      end
    end

    def find_item_by_barcode(barcode)
      item = Item.find_by(barcode: barcode.to_s.strip)
      item ? item.warehouse_payload : {}
    end

    def find_item_by_sku!(sku)
      Item.find_by!(sku: sku.to_s)
    rescue ActiveRecord::RecordNotFound
      raise InventoryError, "Unknown SKU #{sku}"
    end

    def add_stock(barcode:, name:, quantity:)
      qty = quantity.to_i
      raise InventoryError, "quantity must be greater than 0" unless qty.positive?

      item = find_or_create_item!(barcode: barcode, name: name)

      Item.transaction do
        item.lock!
        new_balance = item.warehouse_quantity + qty
        item.update!(warehouse_quantity: new_balance, is_available: true)
        WarehouseMovement.create!(
          item: item,
          movement_type: "warehouse_receive",
          quantity_delta: qty,
          balance_after: new_balance,
          reference_code: "warehouse_add_stock"
        )
      end

      item.warehouse_payload
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def set_machine_quantity(machine_id:, sku:, quantity:)
      target_qty = quantity.to_i
      raise InventoryError, "quantity must be >= 0" if target_qty.negative?

      machine = Machine.find_by(id: machine_id.to_s)
      raise InventoryError, "Machine not found" unless machine

      item = find_item_by_sku!(sku)
      existing_items = nil

      Item.transaction do
        item.lock!
        inventory = MachineInventory.lock.find_or_initialize_by(machine_id: machine.id, item_id: item.id)
        current_qty = inventory.quantity.to_i
        delta = target_qty - current_qty

        if delta.zero?
          existing_items = machine_inventory[machine.id]
          next
        end

        new_balance = item.warehouse_quantity - delta
        if new_balance.negative?
          raise InventoryError, "Insufficient warehouse stock for #{item.name}"
        end

        movement_type = delta.positive? ? "machine_fill" : "machine_return"
        item.update!(warehouse_quantity: new_balance)
        inventory.update!(quantity: target_qty)
        WarehouseMovement.create!(
          item: item,
          movement_type: movement_type,
          quantity_delta: -delta,
          balance_after: new_balance,
          machine_id: machine.id,
          reference_code: "machine_inventory_set"
        )
      end

      existing_items || machine_inventory[machine.id]
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def create_shipment!(description:, amount:, scheduled_for:, status:)
      shipment = Shipment.create!(
        description: description.to_s,
        amount: amount.to_i,
        scheduled_for: parse_time!(scheduled_for),
        status: status.presence || "scheduled"
      )
      shipment.payload
    rescue ActiveRecord::RecordInvalid => e
      raise InventoryError, e.message
    end

    def shipments
      Shipment.order(scheduled_for: :asc, id: :asc).map(&:payload)
    end

    def items_index
      Item.order(:name, :sku).map(&:item_payload)
    end

    def find_item(id)
      item = Item.find_by(id: id)
      item&.item_payload
    end

    def find_item_by_slot(slot_number)
      item = Item.find_by(slot_number: slot_number.to_s)
      item&.item_payload
    end

    def create_item!(payload)
      Item.transaction do
        quantity = payload.fetch("quantity", 0).to_i
        item = Item.create!(
          sku: payload["sku"].presence || derive_sku(payload["barcode"], payload["name"]),
          name: payload["name"].to_s,
          description: payload["description"],
          price: payload.fetch("price", 0).to_f,
          warehouse_quantity: quantity,
          slot_number: payload["slot_number"],
          is_available: payload.key?("is_available") ? !!payload["is_available"] : true,
          image_url: payload["image_url"],
          barcode: payload["barcode"].presence
        )

        if quantity.positive?
          WarehouseMovement.create!(
            item: item,
            movement_type: "warehouse_receive",
            quantity_delta: quantity,
            balance_after: quantity,
            reference_code: "item_create"
          )
        end

        item.item_payload
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def update_item!(id, payload)
      item = Item.find(id)

      Item.transaction do
        item.lock!
        next_qty = payload.key?("quantity") ? payload["quantity"].to_i : item.warehouse_quantity
        raise InventoryError, "quantity must be >= 0" if next_qty.negative?

        delta = next_qty - item.warehouse_quantity
        item.assign_attributes(
          sku: payload["sku"].presence || item.sku,
          name: payload.key?("name") ? payload["name"].to_s : item.name,
          description: payload.key?("description") ? payload["description"] : item.description,
          price: payload.key?("price") ? payload["price"].to_f : item.price,
          slot_number: payload.key?("slot_number") ? payload["slot_number"] : item.slot_number,
          is_available: payload.key?("is_available") ? !!payload["is_available"] : item.is_available,
          image_url: payload.key?("image_url") ? payload["image_url"] : item.image_url,
          barcode: payload.key?("barcode") ? payload["barcode"].presence : item.barcode,
          warehouse_quantity: next_qty
        )
        item.save!

        if delta.nonzero?
          WarehouseMovement.create!(
            item: item,
            movement_type: "warehouse_adjustment",
            quantity_delta: delta,
            balance_after: next_qty,
            reference_code: "item_update"
          )
        end

        item.item_payload
      end
    rescue ActiveRecord::RecordNotFound
      raise InventoryError, "Item with id #{id} not found"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def destroy_item!(id)
      item = Item.find_by(id: id)
      raise InventoryError, "Item with id #{id} not found" unless item

      if item.warehouse_quantity.to_i != 0
        raise InventoryError, "Item cannot be deleted while warehouse stock remains"
      end

      if item.machine_inventories.exists?
        raise InventoryError, "Item cannot be deleted while machine inventory rows remain"
      end

      if item.warehouse_movements.exists?
        raise InventoryError, "Item cannot be deleted while warehouse movement history exists"
      end

      item.destroy!
    rescue ActiveRecord::RecordInvalid => e
      raise InventoryError, e.message
    end

    private

    def find_or_create_item!(barcode:, name:)
      normalized_barcode = barcode.to_s.strip
      normalized_name = name.to_s.strip
      raise InventoryError, "name is required" if normalized_name.blank?

      if normalized_barcode.present?
        Item.find_or_create_by!(barcode: normalized_barcode) do |item|
          item.sku = derive_sku(normalized_barcode, normalized_name)
          item.name = normalized_name
          item.is_available = true
        end
      else
        sku = derive_sku(nil, normalized_name)
        Item.find_or_create_by!(sku: sku) do |item|
          item.name = normalized_name
          item.is_available = true
        end
      end
    end

    def derive_sku(barcode, name)
      candidate = barcode.to_s.strip
      candidate = name.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") if candidate.blank?
      candidate.presence || "sku_#{SecureRandom.hex(4)}"
    end

    def parse_time!(value)
      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      raise InventoryError, "Invalid date"
    end
  end
end
