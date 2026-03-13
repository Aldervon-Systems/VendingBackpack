# frozen_string_literal: true

module Api
  class MachinesController < Api::BaseController
    def index
      render json: machines.map { |machine| machine_payload(machine) }
    end

    def show
      machine = Machine.find_by(id: params[:id].to_s)
      if machine
        render json: machine_payload(machine)
      else
        render json: { detail: "Machine not found" }, status: :not_found
      end
    end

    private

    def machines
      Machine.order(:name, :id)
    end

    def machine_payload(machine)
      {
        "id" => machine.id,
        "name" => machine.name,
        "vin" => machine.vin,
        "organization_id" => machine.organization_id,
        "status" => machine.status,
        "battery" => machine.battery,
        "lat" => machine.lat,
        "lng" => machine.lng,
        "location" => machine.location
      }
    end
  end
end
