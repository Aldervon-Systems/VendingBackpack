class Employee < ApplicationRecord
  self.primary_key = :id
  has_one :route, dependent: :destroy
end
