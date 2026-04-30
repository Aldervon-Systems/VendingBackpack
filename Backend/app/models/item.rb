class Item < ApplicationRecord
  belongs_to :organization, optional: true
  has_many :machine_inventories, dependent: :destroy
  has_many :warehouse_movements, dependent: :destroy

  before_validation :normalize_blank_values
  before_validation :assign_single_organization_if_blank

  validates :sku, presence: true, uniqueness: { scope: :organization_id }
  validates :name, presence: true
  validates :barcode, uniqueness: { scope: :organization_id }, allow_blank: true
  validates :warehouse_quantity, numericality: { greater_than_or_equal_to: 0 }

  def inventory_payload
    {
      "itemId" => id,
      "sku" => sku,
      "name" => name,
      "quantity" => warehouse_quantity,
      "barcode" => barcode
    }
  end

  def payload
    {
      "id" => id,
      "sku" => sku,
      "name" => name,
      "description" => description,
      "price" => price.to_f,
      "quantity" => warehouse_quantity,
      "slotNumber" => slot_number,
      "isAvailable" => is_available,
      "imageUrl" => image_url,
      "barcode" => barcode,
      "createdAt" => created_at&.iso8601,
      "updatedAt" => updated_at&.iso8601
    }
  end

  private

  def normalize_blank_values
    self.barcode = barcode.presence
    self.slot_number = slot_number.presence
    self.image_url = image_url.presence
    self.description = description.presence
  end

  def assign_single_organization_if_blank
    return if organization_id.present?

    self.organization = Organization.first if Organization.count == 1
  end
end
