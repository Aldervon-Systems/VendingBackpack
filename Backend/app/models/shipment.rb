class Shipment < ApplicationRecord
  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :scheduled_for, presence: true
  validates :status, presence: true

  def payload
    {
      "id" => id.to_s,
      "description" => description,
      "amount" => amount,
      "date" => scheduled_for.iso8601,
      "status" => status
    }
  end
end
