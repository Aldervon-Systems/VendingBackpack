# frozen_string_literal: true

module Api
  class EmployeesController < Api::BaseController
    before_action :require_manager!, only: %i[routes_index assign_route update_stops autogenerate_all]
    before_action only: %i[show routes_for] do
      require_self_or_manager!(params[:id])
    end
    before_action :ensure_employee_parity_for_self!, only: %i[routes_for]

    def show
      employee = Employee.find_by(id: params[:id])
      if employee
        render json: employee.payload
      else
        render json: { detail: "Employee not found" }, status: :not_found
      end
    end

    def routes_index
      render json: Route.all
    end

    def routes_for
      route = Route.find_by(employee_id: params[:id])
      render json: route || { stops: [] }
    end

    def assign_route
      employee_id = params[:id].to_s
      machine_id = params[:machine_id].to_s

      machine = Machine.find_by(id: machine_id)
      unless machine
        return render json: { error: "Location not found" }, status: :not_found
      end

      employee = Employee.find_by(id: employee_id)
      unless employee
        return render json: { error: "Employee not found" }, status: :not_found
      end

      route = Route.find_or_create_by!(employee_id: employee_id) do |r|
        r.employee_name = employee.name
      end

      # Check if already assigned
      if route.stops.exists?(machine_id: machine_id)
        return render json: route
      end

      # Add new stop with Insertion Heuristic
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

        # Bump positions of existing stops
        route.stops.where("position >= ?", best_index).update_all("position = position + 1")
        route.stops.create!(machine: machine, position: best_index)
      end

      # Recalculate distance
      update_route_distance(route)
      
      render json: route.reload
    end

    def update_stops
      employee_id = params[:id].to_s
      stop_ids = params[:stop_ids] || []

      employee = Employee.find_by(id: employee_id)
      return render json: { error: "Employee not found" }, status: :not_found unless employee

      route = Route.find_or_create_by!(employee_id: employee_id) do |r|
        r.employee_name = employee.name
      end

      # Clear and rebuild stops
      route.stops.destroy_all
      
      stop_ids.each_with_index do |sid, index|
        machine = Machine.find_by(id: sid)
        route.stops.create!(machine: machine, position: index) if machine
      end

      update_route_distance(route)
      
      render json: route.reload
    end

    def autogenerate_all
      all_machines = Machine.all
      active_employees = Employee.where(is_active: true)
      
      # 1. Clear existing routes
      Route.destroy_all
      
      generated_routes = []
      
      # 2. Assign machines to nearest employee
      all_machines.each do |machine|
        next if machine.id == "W-01"

        nearest_emp = active_employees.min_by do |emp|
          base_loc = Machine.find_by(name: emp.location) || all_machines.first
          dist(base_loc.as_json, machine.as_json)
        end

        route = generated_routes.find { |r| r.employee_id == nearest_emp.id }
        unless route
          route = Route.create!(
            employee: nearest_emp,
            employee_name: nearest_emp.name
          )
          generated_routes << route
        end
        
        # Add temporarily for sorting
        route.stops.build(machine: machine, position: route.stops.length)
      end

      # 3. Sort stops and save
      generated_routes.each do |route|
        next if route.stops.empty?
        
        sorted_stops = []
        emp = route.employee
        current_pos = Machine.find_by(name: emp.location) || all_machines.first
        
        remaining = route.stops.to_a
        route.stops.delete_all # Clear built ones

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
      
      render json: { status: "success", routes: Route.all }
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

    def dist(p1, p2)
      # p1 and p2 are expected to be hashes or model as_json results
      Math.sqrt(((p1["lat"] || 0) - (p2["lat"] || 0))**2 + ((p1["lng"] || 0) - (p2["lng"] || 0))**2)
    end
  end
end
