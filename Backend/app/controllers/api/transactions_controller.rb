# frozen_string_literal: true

require "time"

module Api
  class TransactionsController < Api::BaseController
    before_action :require_manager!, only: %i[refund]

    def index
      render json: transactions
    end

    def show
      transaction = find_transaction(params[:id])
      if transaction
        render json: transaction
      else
        render json: { detail: "Transaction #{params[:id]} not found" }, status: :not_found
      end
    end

    def create
      payload = JSON.parse(request.raw_post.presence || "{}")
      item_id = payload["item_id"].to_i
      if item_id <= 0
        render json: { detail: "item_id is required" }, status: :bad_request
        return
      end

      item = find_item(item_id)
      unless item
        render json: { detail: "Item #{item_id} not found" }, status: :not_found
        return
      end

      if item["quantity"].to_i <= 0 || item["is_available"] == false
        render json: { detail: "Item #{item['name']} is not available" }, status: :bad_request
        return
      end

      amount = payload["amount"] || item["price"]
      if amount.to_f <= 0
        render json: { detail: "amount must be greater than 0" }, status: :bad_request
        return
      end

      now = Time.now.utc.iso8601
      transaction = {
        "id" => next_id,
        "item_id" => item_id,
        "item_name" => payload["item_name"] || item["name"],
        "slot_number" => payload["slot_number"] || item["slot_number"],
        "amount" => amount.to_f,
        "status" => "completed",
        "payment_method" => payload["payment_method"],
        "user_id" => payload["user_id"],
        "created_at" => now,
        "completed_at" => now
      }

      transactions << transaction
      decrement_item(item)

      render json: transaction, status: :created
    end

    def refund
      transaction = find_transaction(params[:id])
      unless transaction
        render json: { detail: "Transaction #{params[:id]} not found" }, status: :not_found
        return
      end

      if transaction["status"] == "refunded"
        render json: { detail: "Transaction already refunded" }, status: :bad_request
        return
      end

      transaction["status"] = "refunded"
      restore_item(transaction["item_id"])

      render json: transaction
    end

    private

    def transactions
      Fixtures::MutableStore.transactions
    end

    def items
      Fixtures::MutableStore.items
    end

    def find_transaction(id_param)
      transactions.find { |tx| tx["id"].to_i == id_param.to_i }
    end

    def find_item(item_id)
      items.find { |it| it["id"].to_i == item_id.to_i }
    end

    def next_id
      (transactions.map { |tx| tx["id"].to_i }.max || 0) + 1
    end

    def decrement_item(item)
      qty = item["quantity"].to_i - 1
      item["quantity"] = [qty, 0].max
      item["is_available"] = false if item["quantity"].to_i <= 0
      item["updated_at"] = Time.now.utc.iso8601
    end

    def restore_item(item_id)
      item = find_item(item_id)
      return unless item

      item["quantity"] = item["quantity"].to_i + 1
      item["is_available"] = true
      item["updated_at"] = Time.now.utc.iso8601
    end
  end
end
