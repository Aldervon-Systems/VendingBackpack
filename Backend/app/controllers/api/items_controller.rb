# frozen_string_literal: true

require "time"

module Api
  class ItemsController < Api::BaseController
    before_action :require_manager!, only: %i[create update destroy]

    def index
      render json: InventoryAuthority.items_index
    end

    def show
      item = InventoryAuthority.find_item(params[:id])
      if item
        render json: item
      else
        render json: { detail: "Item with id #{params[:id]} not found" }, status: :not_found
      end
    end

    def slot
      slot_number = params[:slot_number].to_s
      item = InventoryAuthority.find_item_by_slot(slot_number)
      if item
        render json: item
      else
        render json: { detail: "Item in slot #{slot_number} not found" }, status: :not_found
      end
    end

    def create
      payload = JSON.parse(request.raw_post.presence || "{}")
      error = validate_payload(payload, required: %w[name price slot_number])
      if error
        render json: { detail: error }, status: :bad_request
        return
      end

      slot_number = payload["slot_number"].to_s
      if slot_number.present? && Item.exists?(slot_number: slot_number)
        render json: { detail: "Slot #{slot_number} is already occupied" }, status: :bad_request
        return
      end

      item = InventoryAuthority.create_item!(payload)
      render json: item, status: :created
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def update
      payload = JSON.parse(request.raw_post.presence || "{}")
      if payload["slot_number"].present? && Item.where(slot_number: payload["slot_number"].to_s).where.not(id: params[:id]).exists?
        render json: { detail: "Slot #{payload['slot_number']} is already occupied" }, status: :bad_request
        return
      end
      if payload.key?("price") && payload["price"].to_f <= 0
        render json: { detail: "price must be greater than 0" }, status: :bad_request
        return
      end
      if payload.key?("quantity") && payload["quantity"].to_i < 0
        render json: { detail: "quantity must be >= 0" }, status: :bad_request
        return
      end

      item = InventoryAuthority.update_item!(params[:id], payload)
      render json: item
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def destroy
      item = InventoryAuthority.find_item(params[:id])
      unless item
        render json: { detail: "Item with id #{params[:id]} not found" }, status: :not_found
        return
      end

      InventoryAuthority.destroy_item!(params[:id])
      head :no_content
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    private

    def validate_payload(payload, required: [])
      missing = required.select { |key| payload[key].to_s.strip.empty? }
      return "Missing required fields: #{missing.join(', ')}" unless missing.empty?

      return "price must be greater than 0" if payload.key?("price") && payload["price"].to_f <= 0
      return "quantity must be >= 0" if payload.key?("quantity") && payload["quantity"].to_i < 0

      nil
    end
  end
end
