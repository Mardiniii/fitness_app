# Global equipment catalogue. resistance_label carries band colour, which in
# Cristian's plans IS the load ("power band verde") -- so it stays structured
# rather than living in a free-text note.
class EquipmentItem < ApplicationRecord
  pg_enum :kind, %w[dumbbell barbell kettlebell band machine bodyweight cardio accessory other],
          prefix: :kind, validate: true
  pg_enum :default_load_unit, %w[lb kg], prefix: true, validate: true

  has_many :client_equipment, dependent: :destroy
  has_many :prescribed_sets,  dependent: :nullify

  validates :name_es, presence: true, uniqueness: true

  def display_name = [ name_es, resistance_label ].compact_blank.uniq.join(" ")
end
