# What this client actually owns. A plan referencing equipment they do not have
# is not executable, so the authoring UI warns at write time.
class ClientEquipment < ApplicationRecord
  belongs_to :client_profile
  belongs_to :equipment_item

  validates :client_profile_id, uniqueness: { scope: :equipment_item_id }
end
