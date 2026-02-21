# frozen_string_literal: true

module Api
  class WarehouseController < Api::BaseController
    before_action :require_manager!, only: %i[update_inventory add_stock add_shipment]

    def warehouse
      render json: Fixtures::MockApi.new.warehouse_inventory
    end
    
    def inventory
      render json: Fixtures::MutableStore.inventory
    end

    def item
      barcode = params[:barcode].to_s
      render json: Fixtures::MockApi.new.find_item_by_barcode(barcode)
    end

    def daily_stats
      render json: Fixtures::MockApi.new.daily_stats
    end

    def update_inventory
      machine_id = params[:machine_id]
      sku = params[:sku]
      new_qty = params[:quantity].to_i

      Fixtures::MutableStore.update_inventory_item(machine_id, sku, new_qty)
      render json: { status: "success", machine_id: machine_id, sku: sku, quantity: new_qty }
    end

    def add_stock
      barcode = params[:barcode].to_s
      name = params[:name].to_s
      qty = params[:quantity].to_i

      Fixtures::MutableStore.add_to_central_stock(barcode, name, qty)
      render json: { status: "success", barcode: barcode, name: name, quantity: qty }
    end

    def get_shipments
      render json: Fixtures::MutableStore.shipments
    end

    def add_shipment
      shipment = {
        "id" => "ship_#{Time.now.to_i}",
        "description" => params[:description].to_s,
        "amount" => params[:amount].to_i,
        "date" => params[:date] || Time.now.iso8601,
        "status" => params[:status] || "scheduled"
      }
      Fixtures::MutableStore.shipments << shipment
      Fixtures::MutableStore.save_json("shipments.json", Fixtures::MutableStore.shipments)
      render json: shipment
    end
  end
end
