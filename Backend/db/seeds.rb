# Load fixtures
employees_json = JSON.parse(File.read(Rails.root.join('data', 'fixtures', 'employees.json')))
locations_json = JSON.parse(File.read(Rails.root.join('data', 'fixtures', 'locations.json')))
routes_json = JSON.parse(File.read(Rails.root.join('data', 'fixtures', 'employee_routes.json')))

puts "Seeding employees..."
employees_json.each do |data|
  Employee.find_or_create_by!(id: data['id']) do |e|
    e.name = data['name']
    e.color = data['color']
    e.department = data['department']
    e.location = data['location']
    e.floor = data['floor']
    e.building = data['building']
    e.is_active = data['is_active']
  end
end

puts "Seeding machines..."
locations_json.each do |data|
  Machine.find_or_create_by!(id: data['id']) do |m|
    m.name = data['name']
    m.lat = data['lat']
    m.lng = data['lng']
  end
end

puts "Seeding routes..."
routes_json.each do |data|
  employee = Employee.find_by(id: data['employee_id'])
  next unless employee

  route = Route.find_or_initialize_by(employee_id: employee.id)
  route.employee = employee
  route.employee_name = data['employee_name']
  route.distance_meters = data['distance_meters'] || 0
  route.duration_seconds = data['duration_seconds'] || 0
  route.save!

  route.stops.destroy_all

  (data['stops'] || []).each_with_index do |stop_data, index|
    machine = Machine.find_by(id: stop_data['id'])
    if machine
      Stop.create!(route: route, machine: machine, position: index)
    end
  end
end
