# frozen_string_literal: true

module Api
  class MachinesController < Api::BaseController
    def index
      render json: machines.map(&:payload)
    end

    def show
      machine = current_organization.machines.find_by(id: params[:id].to_s)
      if machine
        render json: machine.payload
      else
        render json: { detail: "Machine not found" }, status: :not_found
      end
    end

    private

    def machines
      current_organization.machines.order(:name, :id)
    end
  end
end
