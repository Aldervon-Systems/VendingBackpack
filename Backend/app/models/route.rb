class Route < ApplicationRecord
  belongs_to :employee
  has_many :stops, -> { order(position: :asc) }, dependent: :destroy
  
  def as_json(options = {})
    super(options.merge(include: :stops))
  end
end
