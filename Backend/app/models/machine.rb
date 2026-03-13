class Machine < ApplicationRecord
  self.primary_key = :id

  has_many :machine_inventories, foreign_key: :machine_id, primary_key: :id, dependent: :destroy
  has_many :stops, foreign_key: :machine_id, primary_key: :id, dependent: :nullify
end
