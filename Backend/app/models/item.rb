class Item < ApplicationRecord
  has_many :machine_inventories, dependent: :destroy
  has_many :warehouse_movements, dependent: :destroy

  before_validation :normalize_blank_values

  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true
  validates :barcode, uniqueness: true, allow_blank: true
  validates :warehouse_quantity, numericality: { greater_than_or_equal_to: 0 }

  def warehouse_payload
    {
      "sku" => sku,
      "name" => name,
      "qty" => warehouse_quantity,
      "barcode" => barcode.to_s
    }
  end

  def item_payload
    {
      "id" => id,
      "sku" => sku,
      "name" => name,
      "description" => description,
      "price" => price.to_f,
      "quantity" => warehouse_quantity,
      "slot_number" => slot_number,
      "is_available" => is_available,
      "image_url" => image_url,
      "barcode" => barcode,
      "created_at" => created_at,
      "updated_at" => updated_at
    }
  end

  private

  def normalize_blank_values
    self.barcode = barcode.presence
    self.slot_number = slot_number.presence
    self.image_url = image_url.presence
    self.description = description.presence
  end
end
