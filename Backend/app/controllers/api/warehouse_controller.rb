# frozen_string_literal: true

module Api
  class WarehouseController < ApplicationController
    def warehouse
      render json: Fixtures::MockApi.new.warehouse_inventory
    end

    def item
      barcode = params[:barcode].to_s
      render json: Fixtures::MockApi.new.find_item_by_barcode(barcode)
    end

    def daily_stats
      render json: Fixtures::MockApi.new.daily_stats
    end
  end
end
