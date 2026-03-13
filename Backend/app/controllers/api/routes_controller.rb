# frozen_string_literal: true

module Api
  class RoutesController < Api::BaseController
    def routes
      render json: {
        locations: Machine.where.not(lat: nil, lng: nil).order(:name, :id).map { |machine| machine_payload(machine) },
        paths: []
      }
    end

    def employees
      render json: Employee.order(:name, :id).map(&:payload)
    end

    private

    def machine_payload(machine)
      {
        "id" => machine.id,
        "name" => machine.name,
        "lat" => machine.lat,
        "lng" => machine.lng,
        "location" => machine.location
      }
    end
  end
end
