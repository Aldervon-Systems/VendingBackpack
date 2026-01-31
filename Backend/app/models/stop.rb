class Stop < ApplicationRecord
  belongs_to :route
  belongs_to :machine

  def as_json(options = {})
    {
      id: machine.id,
      name: machine.name,
      lat: machine.lat,
      lng: machine.lng
    }
  end
end
