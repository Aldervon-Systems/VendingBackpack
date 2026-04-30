# frozen_string_literal: true

require "securerandom"

class InventoryAuthority
  class InventoryError < StandardError; end

  class << self
    def warehouse_inventory(organization:)
      organization.items.order(:name, :sku).map(&:inventory_payload)
    end

    def machine_inventory(organization:)
      organization.machines.order(:name, :id).includes(machine_inventories: :item).map do |machine|
        machine_inventory_snapshot(machine)
      end
    end

    def find_item_by_barcode(barcode, organization:)
      item = organization.items.find_by(barcode: barcode.to_s.strip)
      item&.payload
    end

    def find_item_by_sku!(sku, organization:)
      organization.items.find_by!(sku: sku.to_s)
    rescue ActiveRecord::RecordNotFound
      raise InventoryError, "Unknown SKU #{sku}"
    end

    def add_stock(barcode:, name:, quantity:, organization:)
      qty = quantity.to_i
      raise InventoryError, "quantity must be greater than 0" unless qty.positive?

      item = find_or_create_item!(barcode: barcode, name: name, organization: organization)

      Item.transaction do
        item.lock!
        new_balance = item.warehouse_quantity + qty
        item.update!(warehouse_quantity: new_balance, is_available: true)
        WarehouseMovement.create!(
          organization: organization,
          item: item,
          movement_type: "warehouse_receive",
          quantity_delta: qty,
          balance_after: new_balance,
          reference_code: "warehouse_add_stock"
        )
      end

      item.inventory_payload
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def set_machine_quantity(machine_id:, sku:, quantity:, organization:)
      target_qty = quantity.to_i
      raise InventoryError, "quantity must be >= 0" if target_qty.negative?

      machine = organization.machines.find_by(id: machine_id.to_s)
      raise InventoryError, "Machine not found" unless machine

      item = find_item_by_sku!(sku, organization: organization)
      Item.transaction do
        item.lock!
        inventory = MachineInventory.lock.find_or_initialize_by(machine_id: machine.id, item_id: item.id)
        current_qty = inventory.quantity.to_i
        delta = target_qty - current_qty

        if delta.zero?
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
          organization: organization,
          item: item,
          movement_type: movement_type,
          quantity_delta: -delta,
          balance_after: new_balance,
          machine_id: machine.id,
          reference_code: "machine_inventory_set"
        )
      end

      machine_inventory_snapshot(machine.reload)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def create_shipment!(description:, amount:, scheduled_for:, status:, organization:)
      shipment = Shipment.create!(
        organization: organization,
        description: description.to_s,
        amount: amount.to_i,
        scheduled_for: parse_time!(scheduled_for),
        status: status.presence || "scheduled"
      )
      shipment.payload
    rescue ActiveRecord::RecordInvalid => e
      raise InventoryError, e.message
    end

    def shipments(organization:)
      organization.shipments.order(scheduled_for: :asc, id: :asc).map(&:payload)
    end

    def items_index(organization:)
      organization.items.order(:name, :sku).map(&:payload)
    end

    def find_item(id, organization:)
      item = organization.items.find_by(id: id)
      item&.payload
    end

    def find_item_by_slot(slot_number, organization:)
      item = organization.items.find_by(slot_number: slot_number.to_s)
      item&.payload
    end

    def create_item!(payload, organization:)
      Item.transaction do
        quantity = payload.fetch("quantity", 0).to_i
        item = Item.create!(
          organization: organization,
          sku: payload["sku"].presence || derive_sku(payload["barcode"], payload["name"]),
          name: payload["name"].to_s,
          description: payload["description"],
          price: payload.fetch("price", 0).to_f,
          warehouse_quantity: quantity,
          slot_number: payload["slotNumber"],
          is_available: payload.key?("isAvailable") ? ActiveModel::Type::Boolean.new.cast(payload["isAvailable"]) : true,
          image_url: payload["imageUrl"],
          barcode: payload["barcode"].presence
        )

        if quantity.positive?
          WarehouseMovement.create!(
            organization: organization,
            item: item,
            movement_type: "warehouse_receive",
            quantity_delta: quantity,
            balance_after: quantity,
            reference_code: "item_create"
          )
        end

        item.payload
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def update_item!(id, payload, organization:)
      item = organization.items.find(id)

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
          slot_number: payload.key?("slotNumber") ? payload["slotNumber"] : item.slot_number,
          is_available: payload.key?("isAvailable") ? ActiveModel::Type::Boolean.new.cast(payload["isAvailable"]) : item.is_available,
          image_url: payload.key?("imageUrl") ? payload["imageUrl"] : item.image_url,
          barcode: payload.key?("barcode") ? payload["barcode"].presence : item.barcode,
          warehouse_quantity: next_qty
        )
        item.save!

        if delta.nonzero?
          WarehouseMovement.create!(
            organization: organization,
            item: item,
            movement_type: "warehouse_adjustment",
            quantity_delta: delta,
            balance_after: next_qty,
            reference_code: "item_update"
          )
        end

        item.payload
      end
    rescue ActiveRecord::RecordNotFound
      raise InventoryError, "Item with id #{id} not found"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      raise InventoryError, e.message
    end

    def destroy_item!(id, organization:)
      item = organization.items.find_by(id: id)
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

    def transactions(organization:)
      organization.vending_transactions.order(completed_at: :desc, id: :desc).includes(:item).map(&:payload)
    end

    def find_transaction(id, organization:)
      transaction = organization.vending_transactions.includes(:item).find_by(id: id)
      transaction&.payload
    end

    def create_transaction!(payload, organization:)
      item_id = payload["itemId"].to_i
      raise InventoryError, "itemId is required" if item_id <= 0

      machine_id = payload["machineId"].to_s.strip
      raise InventoryError, "machineId is required" if machine_id.blank?

      item = organization.items.find_by(id: item_id)
      raise InventoryError, "Item #{item_id} not found" unless item

      amount = payload["amount"].presence ? payload["amount"].to_f : item.price.to_f
      raise InventoryError, "amount must be greater than 0" unless amount.positive?

      transaction = nil

      Item.transaction do
        machine = organization.machines.find_by(id: machine_id)
        raise InventoryError, "Machine not found" unless machine

        inventory = MachineInventory.lock.find_by(machine_id: machine.id, item_id: item.id)
        raise InventoryError, "Machine inventory row not found" unless inventory
        raise InventoryError, "Item #{item.name} is not available" if inventory.quantity.to_i <= 0

        inventory.update!(quantity: inventory.quantity.to_i - 1)
        transaction = VendingTransaction.create!(
          organization: organization,
          item: item,
          machine_id: machine.id,
          slot_number: payload["slotNumber"].presence || item.slot_number,
          amount: amount,
          status: VendingTransaction::STATUS_COMPLETED,
          payment_method: payload["paymentMethod"],
          user_id: payload["userId"],
          completed_at: Time.current
        )
      end

      transaction.payload
    rescue ActiveRecord::RecordInvalid => e
      raise InventoryError, e.message
    end

    def refund_transaction!(id, organization:)
      transaction = organization.vending_transactions.includes(:item).find_by(id: id)
      raise InventoryError, "Transaction #{id} not found" unless transaction
      raise InventoryError, "Transaction already refunded" if transaction.status == VendingTransaction::STATUS_REFUNDED

      Item.transaction do
        if transaction.machine_id.present?
          inventory = MachineInventory.lock.find_or_initialize_by(machine_id: transaction.machine_id, item_id: transaction.item_id)
          inventory.quantity = inventory.quantity.to_i + 1
          inventory.save!
        end

        transaction.update!(
          status: VendingTransaction::STATUS_REFUNDED,
          refunded_at: Time.current
        )
      end

      transaction.reload.payload
    rescue ActiveRecord::RecordInvalid => e
      raise InventoryError, e.message
    end

    def daily_stats(organization:)
      base_date = Time.zone.today

      (0..6).map do |offset|
        date = base_date - (6 - offset)
        rows = organization.vending_transactions.where(completed_at: date.beginning_of_day..date.end_of_day)
        amount = rows.sum do |transaction|
          transaction.status == VendingTransaction::STATUS_REFUNDED ? -transaction.amount.to_f : transaction.amount.to_f
        end

        {
          "date" => date.iso8601,
          "amount" => amount.round(2),
          "transactionCount" => rows.count
        }
      end
    end

    private

    def machine_inventory_snapshot(machine)
      rows = machine.machine_inventories
        .joins(:item)
        .includes(:item)
        .where(items: { organization_id: machine.organization_id })
        .order("items.name ASC, items.sku ASC")

      {
        "machineId" => machine.id,
        "machineName" => machine.name,
        "status" => machine.status,
        "location" => machine.location,
        "items" => rows.map(&:payload)
      }
    end

    def find_or_create_item!(barcode:, name:, organization:)
      normalized_barcode = barcode.to_s.strip
      normalized_name = name.to_s.strip
      raise InventoryError, "name is required" if normalized_name.blank?

      if normalized_barcode.present?
        organization.items.find_or_create_by!(barcode: normalized_barcode) do |item|
          item.sku = derive_sku(normalized_barcode, normalized_name)
          item.name = normalized_name
          item.is_available = true
        end
      else
        sku = derive_sku(nil, normalized_name)
        organization.items.find_or_create_by!(sku: sku) do |item|
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
      parsed = Time.zone.parse(value.to_s)
      raise InventoryError, "Invalid date" unless parsed

      parsed
    rescue ArgumentError, TypeError
      raise InventoryError, "Invalid date"
    end
  end
end
