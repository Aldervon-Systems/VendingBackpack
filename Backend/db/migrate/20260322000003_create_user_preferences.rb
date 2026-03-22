class CreateUserPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :user_preferences do |t|
      t.string :user_id, null: false
      t.string :namespace, null: false
      t.integer :version, null: false, default: 1
      t.text :value_json, null: false
      t.timestamps
    end

    add_index :user_preferences, [:user_id, :namespace], unique: true
  end
end
