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
      render json: routes.first || { stops: [] }
    end

    def assign_route
      eid = params[:id].to_s
      machine_id = params[:machine_id].to_s

      # Find location details
      location = Fixtures::MockApi.new.locations.find { |l| l["id"] == machine_id }
      unless location
        return render json: { error: "Location not found" }, status: :not_found
      end

      # Find or create route
      route = employee_routes.find { |r| r["employee_id"].to_s == eid }
      
      unless route
        employee = employees.find { |e| e["id"].to_s == eid }
        unless employee
          return render json: { error: "Employee not found" }, status: :not_found
        end
        
        route = {
          "id" => (employee_routes.map { |r| r["id"] }.max || 0) + 1,
          "employee_id" => employee["id"],
          "employee_name" => employee["name"],
          "distance_meters" => 0,
          "duration_seconds" => 0,
          "stops" => [],
          "created_at" => Time.now.iso8601
        }
      end

      # Check if already assigned
      if route["stops"].any? { |s| s["id"] == machine_id }
        return render json: route
      end

      # Add new stop with Insertion Heuristic (Simple Nearest Neighbor)
      new_stop = {
        "id" => location["id"],
        "name" => location["name"],
        "lat" => location["lat"],
        "lng" => location["lng"]
      }

      if route["stops"].empty?
        route["stops"] << new_stop
      else
        # Find best insertion index to minimize added distance
        best_index = route["stops"].length
        min_added_dist = Float::INFINITY

        # Try inserting at every position
        (0..route["stops"].length).each do |i|
          prev_stop = i > 0 ? route["stops"][i - 1] : nil
          next_stop = i < route["stops"].length ? route["stops"][i] : nil

          dist_added = 0
          if prev_stop
            dist_added += dist(prev_stop, new_stop)
          end
          if next_stop
            dist_added += dist(new_stop, next_stop)
          end
          if prev_stop && next_stop
             # Subtract the edge we represent breaking
             dist_added -= dist(prev_stop, next_stop)
          end

          if dist_added < min_added_dist
            min_added_dist = dist_added
            best_index = i
          end
        end
        
        route["stops"].insert(best_index, new_stop)
      end

      # Recalculate total distance (Euclidean approximation for now)
      total_dist = 0
      route["stops"].each_with_index do |stop, i|
        if i > 0
          total_dist += dist(route["stops"][i-1], stop)
        end
      end
      route["distance_meters"] = total_dist.round(2)

      # Persist update
      Fixtures::MutableStore.update_route(route)
      
      render json: route
    end

    def update_stops
      eid = params[:id].to_s
      stop_ids = params[:stop_ids] || []

      # Find or create route
      route = employee_routes.find { |r| r["employee_id"].to_s == eid }
      unless route
        employee = employees.find { |e| e["id"].to_s == eid }
        return render json: { error: "Employee not found" }, status: :not_found unless employee
        
        route = {
          "id" => (employee_routes.map { |r| r["id"] }.max || 0) + 1,
          "employee_id" => employee["id"],
          "employee_name" => employee["name"],
          "distance_meters" => 0,
          "duration_seconds" => 0,
          "stops" => [],
          "created_at" => Time.now.iso8601
        }
      end

      # Reconstruct stops from IDs
      all_locations = Fixtures::MockApi.new.locations
      new_stops = []
      
      stop_ids.each do |sid|
        loc = all_locations.find { |l| l["id"] == sid }
        if loc
          new_stops << {
            "id" => loc["id"],
            "name" => loc["name"],
            "lat" => loc["lat"],
            "lng" => loc["lng"]
          }
        end
      end

      route["stops"] = new_stops

      # Recalculate total distance
      total_dist = 0
      route["stops"].each_with_index do |stop, i|
        if i > 0
          total_dist += dist(route["stops"][i-1], stop)
        end
      end
      route["distance_meters"] = total_dist.round(2)

      # Persist update
      Fixtures::MutableStore.update_route(route)
      
      render json: route
    end

    private

    def dist(p1, p2)
      # Euclidean distance approximation for simple ordering
      Math.sqrt((p1["lat"] - p2["lat"])**2 + (p1["lng"] - p2["lng"])**2)
    end

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
