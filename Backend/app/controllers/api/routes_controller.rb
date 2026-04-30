# frozen_string_literal: true

module Api
  class RoutesController < Api::BaseController
    def routes
      render json: current_organization.routes.includes(stops: :machine).order(:employee_name, :employee_id).map(&:payload)
    end

    def employees
      render json: current_organization.employees.order(:name, :id).map(&:payload)
    end
  end
end
