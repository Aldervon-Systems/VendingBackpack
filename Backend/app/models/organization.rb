class Organization < ApplicationRecord
  self.primary_key = :id

  has_secure_password :admin_password

  has_many :users, dependent: :nullify
  has_many :machines, dependent: :nullify
  has_many :employees, dependent: :nullify
  has_many :items, dependent: :nullify
  has_many :routes, dependent: :nullify
  has_many :shipments, dependent: :nullify
  has_many :vending_transactions, dependent: :nullify
  has_many :warehouse_movements, dependent: :nullify
  has_many :organization_whitelist_entries, dependent: :destroy
  belongs_to :manager, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true
  validates :totp_seed, presence: true
end
