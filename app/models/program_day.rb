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

  def copy_into!(target_week)
    copy = target_week.program_days.create!(
      position: position, name: name, focus: focus, description: description
    )
    # Top-level blocks only; each block copies its own children, so nested
    # "bloque A + bloque B" structures come across intact.
    program_blocks.order(:position).each { |block| block.copy_into!(day: copy) }
    copy
  end
end
