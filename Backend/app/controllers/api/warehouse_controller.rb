# frozen_string_literal: true

module Api
  class WarehouseController < Api::BaseController
    before_action :require_manager!, only: %i[add_stock add_shipment]

    def warehouse
      render json: InventoryAuthority.warehouse_inventory
    end
    
    def inventory
      render json: InventoryAuthority.machine_inventory
    end

    def item
      barcode = params[:barcode].to_s
      render json: InventoryAuthority.find_item_by_barcode(barcode)
    end

    def daily_stats
      render json: Fixtures::MockApi.new.daily_stats
    end

    def update_inventory
      machine_id = params[:machine_id]
      sku = params[:sku]
      new_qty = params[:quantity].to_i
      ensure_employee_parity!
      return if performed?

      unless authorized_for_machine_update?(machine_id)
        render json: { detail: "Forbidden" }, status: :forbidden
        return
      end

      InventoryAuthority.set_machine_quantity(machine_id: machine_id, sku: sku, quantity: new_qty)
      render json: { status: "success", machine_id: machine_id, sku: sku, quantity: new_qty }
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def add_stock
      barcode = params[:barcode].to_s
      name = params[:name].to_s
      qty = params[:quantity].to_i

      item = InventoryAuthority.add_stock(barcode: barcode, name: name, quantity: qty)
      render json: { status: "success", barcode: item["barcode"], name: item["name"], quantity: qty }
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def get_shipments
      render json: InventoryAuthority.shipments
    end

    def add_shipment
      shipment = InventoryAuthority.create_shipment!(
        description: params[:description],
        amount: params[:amount],
        scheduled_for: params[:date] || Time.now.iso8601,
        status: params[:status]
      )
      render json: shipment
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    private

    def authorized_for_machine_update?(machine_id)
      return true if current_user && current_user["role"].to_s.downcase == "manager"

      route = Route.find_by(employee_id: current_user&.dig("id").to_s)
      route && route.stops.exists?(machine_id: machine_id.to_s)
    end
  end
end
