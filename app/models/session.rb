# One attempt at one program_day, by one client.
class Session < ApplicationRecord
  pg_enum :status, %w[pending in_progress completed skipped], validate: true

  belongs_to :program_assignment
  belongs_to :program_day

  has_many :set_logs, dependent: :destroy

  has_one :client, through: :program_assignment

  scope :completed_first, -> { order(completed_at: :desc) }

  def start!
    update!(status: "in_progress", started_at: Time.current) if status == "pending"
  end

  # all_blocks, not program_blocks: the latter is scoped to top-level blocks, so
  # a day containing a nested "bloque A + bloque B" would report a total that
  # excludes the nested sets -- and progress would sit above 100%.
  def prescribed_set_count
    PrescribedSet.joins(:block_exercise)
                 .where(block_exercises: { program_block_id: program_day.all_blocks.select(:id) })
                 .count
  end

  def logged_set_count = set_logs.where(skipped: false).count

  def progress
    total = prescribed_set_count
    total.zero? ? 0 : ((logged_set_count.to_f / total) * 100).round
  end

  def complete!
    update!(status: "completed", completed_at: Time.current,
            duration_seconds: started_at && (Time.current - started_at).round)
  end

  # Total load moved this session. per_side prescriptions count double, since
  # "15 remo por brazo" means fifteen reps on each arm.
  def total_volume
    set_logs.includes(block_exercise: :exercise).sum do |log|
      next 0 if log.reps_completed.blank? || log.load_value.blank?
      reps = log.reps_completed * (log.block_exercise.per_side? ? 2 : 1)
      reps * log.load_value
    end
  end
end
