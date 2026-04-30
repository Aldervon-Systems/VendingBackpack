# frozen_string_literal: true

module Api
  class EmployeesController < Api::BaseController
    before_action :require_manager!, only: %i[routes_index assign_route update_stops autogenerate_all]
    before_action only: %i[show routes_for] do
      require_self_or_manager!(params[:id])
    end
    before_action :ensure_employee_parity_for_self!, only: %i[routes_for]

    def show
      employee = current_organization.employees.find_by(id: params[:id])
      if employee
        render json: employee.payload
      else
        render json: { detail: "Employee not found" }, status: :not_found
      end
    end

    def routes_index
      render json: current_organization.routes.includes(stops: :machine).order(:employee_name, :employee_id).map(&:payload)
    end

    def routes_for
      employee = current_organization.employees.find_by(id: params[:id])
      unless employee
        render json: { detail: "Employee not found" }, status: :not_found
        return
      end

      route = current_organization.routes.find_by(employee_id: params[:id])
      render json: route ? route.payload : Route.empty_payload(employee)
    end

    def assign_route
      employee_id = params[:id].to_s
      machine_id = params[:machineId].to_s

      machine = current_organization.machines.find_by(id: machine_id)
      unless machine
        return render json: { detail: "Machine not found" }, status: :not_found
      end

      employee = current_organization.employees.find_by(id: employee_id)
      unless employee
        return render json: { detail: "Employee not found" }, status: :not_found
      end

      route = find_or_initialize_route_for(employee)

      if route.stops.exists?(machine_id: machine_id)
        return render json: route.payload
      end

      new_stop_data = { "lat" => machine.lat, "lng" => machine.lng }
      stops_list = route.stops.map { |s| { "lat" => s.machine.lat, "lng" => s.machine.lng, "id" => s.machine_id } }

      if stops_list.empty?
        route.stops.create!(machine: machine, position: 0)
      else
        best_index = stops_list.length
        min_added_dist = Float::INFINITY

        (0..stops_list.length).each do |i|
          prev_stop = i > 0 ? stops_list[i - 1] : nil
          next_stop = i < stops_list.length ? stops_list[i] : nil

          dist_added = 0
          dist_added += dist(prev_stop, new_stop_data) if prev_stop
          dist_added += dist(new_stop_data, next_stop) if next_stop
          dist_added -= dist(prev_stop, next_stop) if prev_stop && next_stop

          if dist_added < min_added_dist
            min_added_dist = dist_added
            best_index = i
          end
        end

        route.stops.where("position >= ?", best_index).update_all("position = position + 1")
        route.stops.create!(machine: machine, position: best_index)
      end

      update_route_distance(route)

      render json: route.reload.payload
    end

    def update_stops
      employee_id = params[:id].to_s
      stop_ids = params[:stopIds] || []

      employee = current_organization.employees.find_by(id: employee_id)
      return render json: { detail: "Employee not found" }, status: :not_found unless employee

      route = find_or_initialize_route_for(employee)

      route.stops.destroy_all

      stop_ids.each_with_index do |sid, index|
        machine = current_organization.machines.find_by(id: sid)
        route.stops.create!(machine: machine, position: index) if machine
      end

      update_route_distance(route)

      render json: route.reload.payload
    end

    def autogenerate_all
      all_machines = current_organization.machines
      active_employees = current_organization.employees.where(is_active: true)

      current_organization.routes.destroy_all

      generated_routes = []

      all_machines.each do |machine|
        next if machine.id == "W-01"

        nearest_emp = active_employees.min_by do |emp|
          base_loc = current_organization.machines.find_by(name: emp.location) || all_machines.first
          dist(base_loc.as_json, machine.as_json)
        end

        route = generated_routes.find { |r| r.employee_id == nearest_emp.id }
        unless route
          route = current_organization.routes.create!(
            employee: nearest_emp,
            employee_name: nearest_emp.name
          )
          generated_routes << route
        end

        route.stops.build(machine: machine, position: route.stops.length)
      end

      generated_routes.each do |route|
        next if route.stops.empty?

        sorted_stops = []
        emp = route.employee
        current_pos = current_organization.machines.find_by(name: emp.location) || all_machines.first

        remaining = route.stops.to_a
        route.stops.delete_all

        while remaining.any?
          next_stop_rec = remaining.min_by { |s| dist(current_pos.as_json, s.machine.as_json) }
          sorted_stops << next_stop_rec.machine
          remaining.delete(next_stop_rec)
          current_pos = next_stop_rec.machine
        end

        sorted_stops.each_with_index do |m, idx|
          route.stops.create!(machine: m, position: idx)
        end

        update_route_distance(route)
      end

      render json: { status: "success", routes: current_organization.routes.includes(stops: :machine).order(:employee_name, :employee_id).map(&:payload) }
    end

    private

    def ensure_employee_parity_for_self!
      return unless current_user && current_user["role"].to_s.downcase == "employee"
      return unless current_user["id"].to_s == params[:id].to_s

      ensure_employee_parity!
    end

    def update_route_distance(route)
      total_dist = 0
      stops = route.stops.reload.to_a
      stops.each_with_index do |stop, i|
        if i > 0
          total_dist += dist(stops[i-1].machine.as_json, stop.machine.as_json)
        end
      end
      route.update!(distance_meters: total_dist.round(2))
    end

    def find_or_initialize_route_for(employee)
      route = current_organization.routes.find_or_initialize_by(employee_id: employee.id)
      route.employee = employee
      route.employee_name = employee.name
      route.save! if route.new_record? || route.changed?
      route
    end

    def dist(p1, p2)
      Math.sqrt(((p1["lat"] || 0) - (p2["lat"] || 0))**2 + ((p1["lng"] || 0) - (p2["lng"] || 0))**2)
    end
  end
end
