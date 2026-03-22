class UserPreference < ApplicationRecord
  validates :user_id, presence: true
  validates :namespace, presence: true
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validates :value_json, presence: true
  validates :namespace, uniqueness: { scope: :user_id }
end
