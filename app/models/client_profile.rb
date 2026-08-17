class ClientProfile < ApplicationRecord
  belongs_to :user

  has_many :client_injuries,  dependent: :destroy
  has_many :client_equipment, dependent: :destroy
  has_many :equipment_items,  through: :client_equipment

  validates :user_id, uniqueness: true
  validates :birth_year, numericality: {
    only_integer: true, greater_than: 1900, less_than_or_equal_to: -> (_) { Date.current.year }
  }, allow_nil: true
  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true

  def age = birth_year && (Date.current.year - birth_year)
end
