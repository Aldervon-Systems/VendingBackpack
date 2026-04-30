# frozen_string_literal: true

module Api
  class WarehouseController < Api::BaseController
    before_action :require_manager!, only: %i[add_stock add_shipment]

    def warehouse
      render json: InventoryAuthority.warehouse_inventory(organization: current_organization)
    end
    
    def inventory
      render json: InventoryAuthority.machine_inventory(organization: current_organization)
    end

    def item
      barcode = params[:barcode].to_s
      item = InventoryAuthority.find_item_by_barcode(barcode, organization: current_organization)
      if item
        render json: item
      else
        render json: { detail: "Item with barcode #{barcode} not found" }, status: :not_found
      end
    end

    def daily_stats
      render json: InventoryAuthority.daily_stats(organization: current_organization)
    end

    def update_inventory
      machine_id = params[:machineId]
      sku = params[:sku]
      new_qty = params[:quantity].to_i
      ensure_employee_parity!
      return if performed?

      unless authorized_for_machine_update?(machine_id)
        render json: { detail: "Forbidden" }, status: :forbidden
        return
      end

      InventoryAuthority.set_machine_quantity(machine_id: machine_id, sku: sku, quantity: new_qty, organization: current_organization)
      render json: { status: "success", machineId: machine_id, sku: sku, quantity: new_qty }
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def add_stock
      barcode = params[:barcode].to_s
      name = params[:name].to_s
      qty = params[:quantity].to_i

      item = InventoryAuthority.add_stock(barcode: barcode, name: name, quantity: qty, organization: current_organization)
      render json: item
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def get_shipments
      render json: InventoryAuthority.shipments(organization: current_organization)
    end

    def add_shipment
      shipment = InventoryAuthority.create_shipment!(
        description: params[:description],
        amount: params[:amount],
        scheduled_for: params[:scheduledFor] || Time.now.iso8601,
        status: params[:status],
        organization: current_organization
      )
      render json: shipment
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    private

    def authorized_for_machine_update?(machine_id)
      return true if current_user && current_user["role"].to_s.downcase == "manager"

      route = current_organization.routes.find_by(employee_id: current_user&.dig("id").to_s)
      route && route.stops.exists?(machine_id: machine_id.to_s)
    end
  end
end
