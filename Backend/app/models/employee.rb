class Employee < ApplicationRecord
  self.primary_key = :id
  has_one :route, dependent: :destroy

  def payload
    {
      "id" => id,
      "name" => name,
      "color" => color,
      "department" => department,
      "location" => location,
      "floor" => floor,
      "building" => building,
      "is_active" => is_active,
      "created_at" => created_at,
      "updated_at" => updated_at
    }
  end
end
