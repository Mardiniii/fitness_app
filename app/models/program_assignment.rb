# The single join between the prescription tree and the execution tree.
# Pins a program_version, never a program.
class ProgramAssignment < ApplicationRecord
  pg_enum :status, %w[active completed paused abandoned], validate: true

  belongs_to :program_version
  belongs_to :client,       class_name: "User", inverse_of: :program_assignments
  belongs_to :practitioner, class_name: "User"

  has_many :sessions, dependent: :destroy
  has_many :check_ins, dependent: :nullify

  has_one :program, through: :program_version

  validates :starts_on, presence: true
  validate  :client_is_not_practitioner

  scope :current, -> { where(status: "active") }

  # Day N unlocks when N-1 completes: the plans are "Dia 1..4", not
  # weekday-anchored, so the client self-schedules.
  def next_program_day
    completed_day_ids = sessions.where(status: "completed").select(:program_day_id)
    program_version.program_weeks.order(:position)
                   .flat_map { |week| week.program_days.order(:position) }
                   .find { |day| completed_day_ids.exclude?(day.id) }
  end

  private

  def client_is_not_practitioner
    errors.add(:client_id, :cannot_coach_self) if client_id.present? && client_id == practitioner_id
  end
end
