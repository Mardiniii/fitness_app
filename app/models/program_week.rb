class ProgramWeek < ApplicationRecord
  belongs_to :program_version

  has_many :program_days, -> { order(:position) }, dependent: :destroy

  validates :position, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :program_version_id }

  def display_name = name.presence || "SEMANA #{position}"
end
