organization_id = "org_aldervon"
seed_totp = ENV.fetch("SEED_ADMIN_TOTP_SEED", "JBSWY3DPEHPK3PXP")
seed_admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "admin")
seed_user_password = ENV.fetch("SEED_USER_PASSWORD", "password123")

puts "Seeding organizations..."
organization = Organization.find_or_initialize_by(id: organization_id)
organization.name = "Aldervon Systems"
organization.totp_seed = seed_totp
organization.admin_password = seed_admin_password
organization.admin_password_confirmation = seed_admin_password
organization.save!

puts "Seeding runtime users..."
seed_users = [
  { id: "platform_admin", name: "Platform Admin", email: "platform@aldervon.com", role: "platform_admin" },
  { id: "user_admin", name: "Admin Manager", email: "admin@vbp.com", role: "manager" },
  { id: "renee_goodman", name: "Renee Goodman", email: "renee@aldervon.com", role: "manager" },
  { id: "emp-07", name: "Amanda Jones", email: "amanda.jones@example.com", role: "employee" }
]

seed_users.each do |data|
  user = User.find_or_initialize_by(id: data[:id])
  user.name = data[:name]
  user.email = data[:email]
  user.role = data[:role]
  user.organization = data[:role] == "platform_admin" ? nil : organization
  user.password = seed_user_password
  user.password_confirmation = seed_user_password
  user.save!
end

organization.update!(manager: User.find("renee_goodman"))

puts "Seeding organization whitelist..."
seed_whitelist = [
  "employee@aldervon.com",
  "manager@aldervon.com",
  "admin@aldervon.com",
  "renee@aldervon.com",
  "amanda.jones@example.com"
]

organization.organization_whitelist_entries.delete_all
seed_whitelist.each do |email|
  organization.organization_whitelist_entries.create!(email: email)
end

employees = [
  { id: "emp-07", name: "Amanda Jones", color: 0xFF4A90E2, department: "Operations", location: "Downtown Hub", floor: "2", building: "North Tower", is_active: true, organization_id: organization_id },
  { id: "emp-11", name: "Luis Vega", color: 0xFF50E3C2, department: "Operations", location: "Cambridge Node", floor: "1", building: "West Annex", is_active: true, organization_id: organization_id },
  { id: "emp-13", name: "Maya Chen", color: 0xFFF5A623, department: "Field Service", location: "Harbor Depot", floor: "1", building: "Warehouse", is_active: true, organization_id: organization_id }
]

machines = [
  { id: "M-101", name: "Union Station", lat: 42.3524, lng: -71.0552, location: "Downtown Loop", status: "online", battery: 93, organization_id: "org_aldervon", vin: "VIN-101" },
  { id: "M-120", name: "North Campus", lat: 42.3651, lng: -71.1040, location: "Cambridge North", status: "online", battery: 88, organization_id: "org_aldervon", vin: "VIN-120" },
  { id: "M-130", name: "Harbor Point", lat: 42.3473, lng: -71.0386, location: "Harbor District", status: "online", battery: 81, organization_id: "org_aldervon", vin: "VIN-130" },
  { id: "M-140", name: "Research Annex", lat: 42.3617, lng: -71.0905, location: "Innovation Corridor", status: "attention", battery: 61, organization_id: "org_aldervon", vin: "VIN-140" }
]

items = [
  { sku: "cold_brew", name: "Cold Brew", barcode: "111", description: "Chilled coffee can", price: 4.25, slot_number: "A1", warehouse_quantity: 18, is_available: true, organization_id: organization_id },
  { sku: "sparkling_water", name: "Sparkling Water", barcode: "222", description: "Lime sparkling water", price: 2.75, slot_number: "A2", warehouse_quantity: 24, is_available: true, organization_id: organization_id },
  { sku: "protein_bar", name: "Protein Bar", barcode: "333", description: "Chocolate protein bar", price: 3.5, slot_number: "B1", warehouse_quantity: 14, is_available: true, organization_id: organization_id },
  { sku: "trail_mix", name: "Trail Mix", barcode: "444", description: "Roasted almond trail mix", price: 3.95, slot_number: "B2", warehouse_quantity: 10, is_available: true, organization_id: organization_id }
]

machine_inventory_targets = {
  "M-101" => { "cold_brew" => 4, "protein_bar" => 3 },
  "M-120" => { "sparkling_water" => 5, "trail_mix" => 2 },
  "M-130" => { "cold_brew" => 2, "sparkling_water" => 4 },
  "M-140" => { "protein_bar" => 1, "trail_mix" => 1 }
}

route_targets = {
  "emp-07" => ["M-101", "M-130"],
  "emp-11" => ["M-120"],
  "emp-13" => ["M-140"]
}

shipments = [
  { description: "Downtown restock wave", amount: 48, scheduled_for: Time.zone.now.change(hour: 14, min: 0), status: "scheduled", organization_id: organization_id },
  { description: "Cambridge emergency refill", amount: 18, scheduled_for: Time.zone.now.change(hour: 17, min: 30), status: "scheduled", organization_id: organization_id }
]

transactions = [
  { sku: "cold_brew", machine_id: "M-101", amount: 4.25, payment_method: "card", user_id: "emp-07", completed_at: Time.zone.now.beginning_of_day + 2.hours },
  { sku: "sparkling_water", machine_id: "M-120", amount: 2.75, payment_method: "card", user_id: "emp-11", completed_at: Time.zone.now.beginning_of_day + 4.hours },
  { sku: "trail_mix", machine_id: "M-140", amount: 3.95, payment_method: "mobile", user_id: "emp-13", completed_at: Time.zone.now.beginning_of_day + 5.hours + 30.minutes }
]

puts "Seeding employees..."
employees.each do |data|
  employee = Employee.find_or_initialize_by(id: data[:id])
  employee.assign_attributes(data)
  employee.save!
end

puts "Seeding machines..."
machines.each do |data|
  machine = Machine.find_or_initialize_by(id: data[:id])
  machine.assign_attributes(data)
  machine.save!
end

puts "Seeding items..."
items.each do |data|
  item = Item.find_or_initialize_by(sku: data[:sku])
  item.assign_attributes(data)
  item.save!
end

puts "Seeding machine inventory..."
machine_inventory_targets.each do |machine_id, sku_quantities|
  sku_quantities.each do |sku, quantity|
    item = Item.find_by!(sku: sku)
    row = MachineInventory.find_or_initialize_by(machine_id: machine_id, item_id: item.id)
    row.quantity = quantity
    row.save!
  end
end

puts "Seeding routes..."
route_targets.each do |employee_id, machine_ids|
  employee = Employee.find_by!(id: employee_id)
  route = Route.find_or_initialize_by(employee_id: employee.id)
  route.organization = organization
  route.employee = employee
  route.employee_name = employee.name
  route.distance_meters = 0
  route.duration_seconds = 0
  route.save!

  route.stops.destroy_all

  machine_ids.each_with_index do |machine_id, index|
    machine = Machine.find_by!(id: machine_id)
    route.stops.create!(machine: machine, position: index)
  end

  total_distance = 0
  stops = route.stops.includes(:machine).order(:position).to_a
  stops.each_with_index do |stop, index|
    next if index.zero?

    previous = stops[index - 1].machine
    current = stop.machine
    total_distance += Math.sqrt(((previous.lat || 0) - (current.lat || 0))**2 + ((previous.lng || 0) - (current.lng || 0))**2)
  end
  route.update!(distance_meters: total_distance.round(2))
end

puts "Seeding shipments..."
shipments.each do |data|
  shipment = Shipment.find_or_initialize_by(description: data[:description], scheduled_for: data[:scheduled_for])
  shipment.assign_attributes(data)
  shipment.save!
end

puts "Seeding transactions..."
transactions.each do |data|
  item = Item.find_by!(sku: data[:sku])
  transaction = VendingTransaction.find_or_initialize_by(
    item_id: item.id,
    machine_id: data[:machine_id],
    completed_at: data[:completed_at]
  )
  transaction.slot_number = item.slot_number
  transaction.organization = organization
  transaction.amount = data[:amount]
  transaction.status = VendingTransaction::STATUS_COMPLETED
  transaction.payment_method = data[:payment_method]
  transaction.user_id = data[:user_id]
  transaction.save!
end
