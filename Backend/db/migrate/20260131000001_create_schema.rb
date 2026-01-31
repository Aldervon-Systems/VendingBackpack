class CreateSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :employees, id: :string do |t|
      t.string :name
      t.integer :color
      t.string :department
      t.string :location
      t.string :floor
      t.string :building
      t.boolean :is_active, default: true
      t.timestamps
    end

    create_table :machines, id: :string do |t|
      t.string :name
      t.float :lat
      t.float :lng
      t.timestamps
    end

    create_table :routes do |t|
      t.string :employee_id
      t.string :employee_name
      t.float :distance_meters, default: 0
      t.float :duration_seconds, default: 0
      t.timestamps
    end

    create_table :stops do |t|
      t.references :route, null: false, foreign_key: true
      t.string :machine_id
      t.integer :position
      t.timestamps
    end
    
    add_index :stops, [:route_id, :position]
  end
end
