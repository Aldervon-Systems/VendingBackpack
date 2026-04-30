class AddTenantOwnershipAndPlatformAdmin < ActiveRecord::Migration[7.1]
  TENANT_TABLES = %i[
    employees
    items
    routes
    shipments
    vending_transactions
    warehouse_movements
  ].freeze

  def up
    TENANT_TABLES.each do |table|
      add_column table, :organization_id, :string unless column_exists?(table, :organization_id)
      add_index table, :organization_id unless index_exists?(table, :organization_id)
    end

    add_index :machines, :organization_id unless index_exists?(:machines, :organization_id)

    backfill_tenant_ownership

    remove_index :items, :sku if index_exists?(:items, :sku, unique: true)
    remove_index :items, :barcode if index_exists?(:items, :barcode, unique: true)
    add_index :items, %i[organization_id sku], unique: true, name: "idx_items_org_sku" unless index_exists?(:items, %i[organization_id sku], name: "idx_items_org_sku")
    add_index :items, %i[organization_id barcode], unique: true, name: "idx_items_org_barcode" unless index_exists?(:items, %i[organization_id barcode], name: "idx_items_org_barcode")
    add_index :employees, %i[organization_id id], unique: true, name: "idx_employees_org_id" unless index_exists?(:employees, %i[organization_id id], name: "idx_employees_org_id")
    add_index :routes, %i[organization_id employee_id], name: "idx_routes_org_employee" unless index_exists?(:routes, %i[organization_id employee_id], name: "idx_routes_org_employee")
    add_index :machines, %i[organization_id id], unique: true, name: "idx_machines_org_id" unless index_exists?(:machines, %i[organization_id id], name: "idx_machines_org_id")

    TENANT_TABLES.each do |table|
      add_foreign_key table, :organizations, column: :organization_id, primary_key: :id unless foreign_key_exists?(table, :organizations, column: :organization_id)
    end
    add_foreign_key :machines, :organizations, column: :organization_id, primary_key: :id unless foreign_key_exists?(:machines, :organizations, column: :organization_id)
  end

  def down
    remove_foreign_key :machines, column: :organization_id if foreign_key_exists?(:machines, :organizations, column: :organization_id)
    TENANT_TABLES.each do |table|
      remove_foreign_key table, column: :organization_id if foreign_key_exists?(table, :organizations, column: :organization_id)
    end

    remove_index :machines, name: "idx_machines_org_id" if index_exists?(:machines, %i[organization_id id], name: "idx_machines_org_id")
    remove_index :routes, name: "idx_routes_org_employee" if index_exists?(:routes, %i[organization_id employee_id], name: "idx_routes_org_employee")
    remove_index :employees, name: "idx_employees_org_id" if index_exists?(:employees, %i[organization_id id], name: "idx_employees_org_id")
    remove_index :items, name: "idx_items_org_barcode" if index_exists?(:items, %i[organization_id barcode], name: "idx_items_org_barcode")
    remove_index :items, name: "idx_items_org_sku" if index_exists?(:items, %i[organization_id sku], name: "idx_items_org_sku")
    add_index :items, :sku, unique: true unless index_exists?(:items, :sku)
    add_index :items, :barcode, unique: true unless index_exists?(:items, :barcode)

    remove_index :machines, :organization_id if index_exists?(:machines, :organization_id)
    TENANT_TABLES.each do |table|
      remove_index table, :organization_id if index_exists?(table, :organization_id)
      remove_column table, :organization_id if column_exists?(table, :organization_id)
    end
  end

  private

  def backfill_tenant_ownership
    org_ids = select_values("SELECT id FROM organizations")
    default_org_id = org_ids.one? ? quote(org_ids.first) : nil

    execute <<~SQL.squish
      UPDATE employees
      SET organization_id = (
        SELECT users.organization_id FROM users WHERE users.id = employees.id
      )
      WHERE organization_id IS NULL
        AND EXISTS (SELECT 1 FROM users WHERE users.id = employees.id AND users.organization_id IS NOT NULL)
    SQL

    execute <<~SQL.squish
      UPDATE routes
      SET organization_id = (
        SELECT employees.organization_id FROM employees WHERE employees.id = routes.employee_id
      )
      WHERE organization_id IS NULL
        AND EXISTS (SELECT 1 FROM employees WHERE employees.id = routes.employee_id AND employees.organization_id IS NOT NULL)
    SQL

    execute <<~SQL.squish
      UPDATE vending_transactions
      SET organization_id = (
        SELECT machines.organization_id FROM machines WHERE machines.id = vending_transactions.machine_id
      )
      WHERE organization_id IS NULL
        AND EXISTS (SELECT 1 FROM machines WHERE machines.id = vending_transactions.machine_id AND machines.organization_id IS NOT NULL)
    SQL

    execute <<~SQL.squish
      UPDATE warehouse_movements
      SET organization_id = (
        SELECT machines.organization_id FROM machines WHERE machines.id = warehouse_movements.machine_id
      )
      WHERE organization_id IS NULL
        AND machine_id IS NOT NULL
        AND EXISTS (SELECT 1 FROM machines WHERE machines.id = warehouse_movements.machine_id AND machines.organization_id IS NOT NULL)
    SQL

    return unless default_org_id

    %i[employees items routes shipments vending_transactions warehouse_movements machines].each do |table|
      execute "UPDATE #{table} SET organization_id = #{default_org_id} WHERE organization_id IS NULL"
    end
  end
end
