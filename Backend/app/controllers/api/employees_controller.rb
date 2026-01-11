# frozen_string_literal: true

module Api
  class EmployeesController < ApplicationController
    def show
      employee = employees.find { |e| e["id"].to_s == params[:id].to_s }
      if employee
        render json: normalize_employee(employee)
      else
        render json: { detail: "Employee not found" }, status: :not_found
      end
    end

    def routes_index
      render json: employee_routes
    end

    def routes_for
      eid = params[:id].to_s
      routes = employee_routes.select { |r| r["employee_id"].to_s == eid }
      render json: routes
    end

    private

    def employees
      Fixtures::MockApi.new.employees
    end

    def employee_routes
      Fixtures::MutableStore.employee_routes
    end

    def normalize_employee(employee)
      {
        "id" => employee["id"],
        "name" => employee["name"],
        "color" => employee["color"],
        "department" => employee["department"],
        "location" => employee["location"],
        "floor" => employee["floor"],
        "building" => employee["building"],
        "is_active" => employee.key?("is_active") ? employee["is_active"] : true,
        "created_at" => employee["created_at"],
        "updated_at" => employee["updated_at"]
      }
    end
  end
end
