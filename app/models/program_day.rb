class ProgramDay < ApplicationRecord
  belongs_to :program_week

  # Top-level blocks only. Nested ones hang off their parent.
  has_many :program_blocks, -> { where(parent_block_id: nil).order(:position) },
           dependent: :destroy
  has_many :all_blocks, class_name: "ProgramBlock", dependent: :destroy
  has_many :sessions, dependent: :restrict_with_error

  validates :position, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :program_week_id }

  def display_name = name.presence || "Día #{position}"
end
