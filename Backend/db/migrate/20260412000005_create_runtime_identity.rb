class CreateRuntimeIdentity < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations, id: :string do |t|
      t.string :name, null: false
      t.string :admin_password_digest, null: false
      t.string :totp_seed, null: false
      t.string :manager_id
      t.timestamps
    end

    add_index :organizations, :name, unique: true

    create_table :users, id: :string do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false
      t.string :organization_id
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_foreign_key :users, :organizations, column: :organization_id, primary_key: :id

    add_foreign_key :organizations, :users, column: :manager_id, primary_key: :id

    create_table :organization_whitelist_entries do |t|
      t.string :organization_id, null: false
      t.string :email, null: false
      t.timestamps
    end

    add_index :organization_whitelist_entries, [:organization_id, :email], unique: true, name: "idx_org_whitelist_entries_unique"
    add_foreign_key :organization_whitelist_entries, :organizations, column: :organization_id, primary_key: :id
  end
end
