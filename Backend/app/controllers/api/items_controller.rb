# frozen_string_literal: true

require "time"

module Api
  class ItemsController < ApplicationController
    def index
      render json: items
    end

    def show
      item = find_item(params[:id])
      if item
        render json: item
      else
        render json: { detail: "Item with id #{params[:id]} not found" }, status: :not_found
      end
    end

    def slot
      slot_number = params[:slot_number].to_s
      item = items.find { |it| it["slot_number"].to_s == slot_number }
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
      if items.any? { |it| it["slot_number"].to_s == slot_number }
        render json: { detail: "Slot #{slot_number} is already occupied" }, status: :bad_request
        return
      end

      now = Time.now.utc.iso8601
      item = {
        "id" => next_id,
        "name" => payload["name"].to_s,
        "description" => payload["description"],
        "price" => payload["price"].to_f,
        "quantity" => payload.fetch("quantity", 0).to_i,
        "slot_number" => slot_number,
        "is_available" => payload.key?("is_available") ? !!payload["is_available"] : true,
        "image_url" => payload["image_url"],
        "created_at" => now,
        "updated_at" => nil
      }

      items << item
      render json: item, status: :created
    end

    def update
      item = find_item(params[:id])
      unless item
        render json: { detail: "Item with id #{params[:id]} not found" }, status: :not_found
        return
      end

      payload = JSON.parse(request.raw_post.presence || "{}")
      if payload.key?("price") && payload["price"].to_f <= 0
        render json: { detail: "price must be greater than 0" }, status: :bad_request
        return
      end
      if payload.key?("quantity") && payload["quantity"].to_i < 0
        render json: { detail: "quantity must be >= 0" }, status: :bad_request
        return
      end

      %w[name description price quantity is_available image_url].each do |field|
        item[field] = payload[field] if payload.key?(field)
      end
      item["updated_at"] = Time.now.utc.iso8601

      render json: item
    end

    def destroy
      idx = items.index { |it| it["id"].to_i == params[:id].to_i }
      if idx
        items.delete_at(idx)
        head :no_content
      else
        render json: { detail: "Item with id #{params[:id]} not found" }, status: :not_found
      end
    end

    private

    def items
      Fixtures::MutableStore.items
    end

    def find_item(id_param)
      items.find { |it| it["id"].to_i == id_param.to_i }
    end

    def next_id
      (items.map { |it| it["id"].to_i }.max || 0) + 1
    end

    def validate_payload(payload, required: [])
      missing = required.select { |key| payload[key].to_s.strip.empty? }
      return "Missing required fields: #{missing.join(', ')}" unless missing.empty?

      return "price must be greater than 0" if payload.key?("price") && payload["price"].to_f <= 0
      return "quantity must be >= 0" if payload.key?("quantity") && payload["quantity"].to_i < 0

      nil
    end
  end
end
