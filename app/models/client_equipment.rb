# What this client actually owns. A plan referencing equipment they do not have
# is not executable, so the authoring UI warns at write time.
class ClientEquipment < ApplicationRecord
  # "equipment" is uncountable, so the table is client_equipment while Rails
  # infers client_equipments. Nothing had ever queried through this model, so
  # the mismatch sat there until the practitioner's client page tried to read
  # equipment_items and got PG::UndefinedTable.
  self.table_name = "client_equipment"

  belongs_to :client_profile
  belongs_to :equipment_item

  validates :client_profile_id, uniqueness: { scope: :equipment_item_id }
end
