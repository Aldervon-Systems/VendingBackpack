# frozen_string_literal: true

require "time"

module Api
  class TransactionsController < Api::BaseController
    before_action :require_manager!, only: %i[refund]

    def index
      render json: InventoryAuthority.transactions(organization: current_organization)
    end

    def show
      transaction = InventoryAuthority.find_transaction(params[:id], organization: current_organization)
      if transaction
        render json: transaction
      else
        render json: { detail: "Transaction #{params[:id]} not found" }, status: :not_found
      end
    end

    def create
      payload = JSON.parse(request.raw_post.presence || "{}")
      transaction = InventoryAuthority.create_transaction!(payload, organization: current_organization)
      render json: transaction, status: :created
    rescue InventoryAuthority::InventoryError => e
      render json: { detail: e.message }, status: :unprocessable_entity
    end

    def refund
      transaction = InventoryAuthority.refund_transaction!(params[:id], organization: current_organization)
      render json: transaction
    rescue InventoryAuthority::InventoryError => e
      status = e.message.include?("not found") ? :not_found : :unprocessable_entity
      render json: { detail: e.message }, status: status
    end
  end
end
