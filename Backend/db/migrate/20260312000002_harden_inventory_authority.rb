class HardenInventoryAuthority < ActiveRecord::Migration[7.1]
  def up
    create_table :items do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.string :barcode
      t.text :description
      t.decimal :price, precision: 10, scale: 2, default: 0, null: false
      t.string :slot_number
      t.boolean :is_available, default: true, null: false
      t.string :image_url
      t.integer :warehouse_quantity, default: 0, null: false
      t.timestamps
    end
    add_index :items, :sku, unique: true
    add_index :items, :barcode, unique: true

    add_column :machines, :vin, :string
    add_column :machines, :organization_id, :string
    add_column :machines, :status, :string, default: "online", null: false
    add_column :machines, :battery, :integer, default: 100, null: false
    add_column :machines, :location, :string

    create_table :machine_inventories do |t|
      t.string :machine_id, null: false
      t.references :item, null: false, foreign_key: true
      t.integer :quantity, default: 0, null: false
      t.timestamps
    end
    add_index :machine_inventories, [:machine_id, :item_id], unique: true
    add_foreign_key :machine_inventories, :machines, column: :machine_id, primary_key: :id

    create_table :warehouse_movements do |t|
      t.references :item, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity_delta, null: false
      t.integer :balance_after, null: false
      t.string :machine_id
      t.string :reason
      t.string :reference_code
      t.timestamps
    end
    add_index :warehouse_movements, :machine_id

    create_table :shipments do |t|
      t.string :description, null: false
      t.integer :amount, default: 0, null: false
      t.datetime :scheduled_for, null: false
      t.string :status, default: "scheduled", null: false
      t.timestamps
    end
  end

  def down
    drop_table :shipments
    drop_table :warehouse_movements
    remove_foreign_key :machine_inventories, column: :machine_id
    drop_table :machine_inventories
    remove_column :machines, :location
    remove_column :machines, :battery
    remove_column :machines, :status
    remove_column :machines, :organization_id
    remove_column :machines, :vin
    drop_table :items
  end
end
