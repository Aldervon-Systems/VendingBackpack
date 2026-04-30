# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_29_000006) do
  create_table "employees", id: :string, force: :cascade do |t|
    t.string "name"
    t.integer "color"
    t.string "department"
    t.string "location"
    t.string "floor"
    t.string "building"
    t.boolean "is_active", default: true
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "id"], name: "idx_employees_org_id", unique: true
    t.index ["organization_id"], name: "index_employees_on_organization_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.string "barcode"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "slot_number"
    t.boolean "is_available", default: true, null: false
    t.string "image_url"
    t.integer "warehouse_quantity", default: 0, null: false
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "barcode"], name: "idx_items_org_barcode", unique: true
    t.index ["organization_id", "sku"], name: "idx_items_org_sku", unique: true
    t.index ["organization_id"], name: "index_items_on_organization_id"
  end

  create_table "machine_inventories", force: :cascade do |t|
    t.string "machine_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_machine_inventories_on_item_id"
    t.index ["machine_id", "item_id"], name: "index_machine_inventories_on_machine_id_and_item_id", unique: true
  end

  create_table "machines", id: :string, force: :cascade do |t|
    t.string "name"
    t.float "lat"
    t.float "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "vin"
    t.string "organization_id"
    t.string "status", default: "online", null: false
    t.integer "battery", default: 100, null: false
    t.string "location"
    t.index ["organization_id", "id"], name: "idx_machines_org_id", unique: true
    t.index ["organization_id"], name: "index_machines_on_organization_id"
  end

  create_table "organization_whitelist_entries", force: :cascade do |t|
    t.string "organization_id", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "idx_org_whitelist_entries_unique", unique: true
  end

  create_table "organizations", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "admin_password_digest", null: false
    t.string "totp_seed", null: false
    t.string "manager_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.string "employee_id"
    t.string "employee_name"
    t.float "distance_meters", default: 0.0
    t.float "duration_seconds", default: 0.0
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "employee_id"], name: "idx_routes_org_employee"
    t.index ["organization_id"], name: "index_routes_on_organization_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "description", null: false
    t.integer "amount", default: 0, null: false
    t.datetime "scheduled_for", null: false
    t.string "status", default: "scheduled", null: false
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_shipments_on_organization_id"
  end

  create_table "stops", force: :cascade do |t|
    t.integer "route_id", null: false
    t.string "machine_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["route_id", "position"], name: "index_stops_on_route_id_and_position"
    t.index ["route_id"], name: "index_stops_on_route_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.string "user_id", null: false
    t.string "namespace", null: false
    t.integer "version", default: 1, null: false
    t.text "value_json", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "namespace"], name: "index_user_preferences_on_user_id_and_namespace", unique: true
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vending_transactions", force: :cascade do |t|
    t.integer "item_id", null: false
    t.string "machine_id"
    t.string "slot_number"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "status", default: "completed", null: false
    t.string "payment_method"
    t.string "user_id"
    t.datetime "completed_at", null: false
    t.datetime "refunded_at"
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_vending_transactions_on_item_id"
    t.index ["machine_id"], name: "index_vending_transactions_on_machine_id"
    t.index ["organization_id"], name: "index_vending_transactions_on_organization_id"
    t.index ["status"], name: "index_vending_transactions_on_status"
  end

  create_table "warehouse_movements", force: :cascade do |t|
    t.integer "item_id", null: false
    t.string "movement_type", null: false
    t.integer "quantity_delta", null: false
    t.integer "balance_after", null: false
    t.string "machine_id"
    t.string "reason"
    t.string "reference_code"
    t.string "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_warehouse_movements_on_item_id"
    t.index ["machine_id"], name: "index_warehouse_movements_on_machine_id"
    t.index ["organization_id"], name: "index_warehouse_movements_on_organization_id"
  end

  add_foreign_key "employees", "organizations"
  add_foreign_key "items", "organizations"
  add_foreign_key "machine_inventories", "items"
  add_foreign_key "machine_inventories", "machines"
  add_foreign_key "machines", "organizations"
  add_foreign_key "organization_whitelist_entries", "organizations"
  add_foreign_key "organizations", "users", column: "manager_id"
  add_foreign_key "routes", "organizations"
  add_foreign_key "shipments", "organizations"
  add_foreign_key "stops", "routes"
  add_foreign_key "users", "organizations"
  add_foreign_key "vending_transactions", "items"
  add_foreign_key "vending_transactions", "machines"
  add_foreign_key "vending_transactions", "organizations"
  add_foreign_key "warehouse_movements", "items"
  add_foreign_key "warehouse_movements", "organizations"
end
