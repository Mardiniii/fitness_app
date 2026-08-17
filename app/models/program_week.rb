class ProgramWeek < ApplicationRecord
  belongs_to :program_version

  has_many :program_days, -> { order(:position) }, dependent: :destroy

  validates :position, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :program_version_id }

  def display_name = name.presence || "SEMANA #{position}"

  # His weeks repeat roughly 70% of the time, so duplicating one is the single
  # biggest time saver in authoring. The copy is deep: days, blocks (including
  # nested ones), exercises, prescribed sets and stated alternatives.
  def duplicate!
    transaction do
      copy = copy_into!(program_version, position: next_position)
      copy
    end
  end

  def copy_into!(target_version, position: nil)
    copy = target_version.program_weeks.create!(
      position: position || self.position,
      name: position ? nil : name,   # a duplicate gets the default "SEMANA n"
      focus: focus
    )
    program_days.order(:position).each { |day| day.copy_into!(copy) }
    copy
  end

  private

  def next_position
    (program_version.program_weeks.maximum(:position) || 0) + 1
  end
end
