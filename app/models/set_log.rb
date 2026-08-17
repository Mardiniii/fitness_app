# What actually happened, as opposed to what was prescribed.
#
# block_exercise_id records the prescription; exercise_id records the movement
# actually performed. They differ whenever the client takes a stated
# substitution -- and without both, a substituted session silently corrupts the
# progression history of two exercises at once.
class SetLog < ApplicationRecord
  pg_enum :load_unit, %w[lb kg], prefix: true, validate: true

  belongs_to :session
  belongs_to :block_exercise
  belongs_to :exercise

  has_one :program_assignment, through: :session

  validates :set_number,     presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :segment_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :client_uuid, presence: true, uniqueness: true
  validates :rpe_reported, numericality: {
    greater_than_or_equal_to: 1, less_than_or_equal_to: 10
  }, allow_nil: true
  validate :substitution_is_acceptable

  # The column defaults to gen_random_uuid() in Postgres, but Rails cannot
  # evaluate a function default before the INSERT -- so a new record arrives at
  # validation with client_uuid still nil and never saves. The phone supplies
  # this key when JS is running (it is what makes a replayed offline queue
  # idempotent); this covers the plain server-rendered path.
  before_validation { self.client_uuid ||= SecureRandom.uuid }

  scope :done, -> { where(skipped: false).where.not(completed_at: nil) }

  # Powers the "last time" panel -- the single most valuable element on the
  # set-logging screen, and the thing a PDF can never give you.
  def self.previous_for(exercise_id:, before: Time.current, limit: 8)
    done.where(exercise_id: exercise_id)
        .where(completed_at: ...before)
        .order(completed_at: :desc)
        .limit(limit)
  end

  def substituted? = exercise_id != block_exercise&.exercise_id

  # "10 × 50 lb · RPE 9"
  def summary
    parts = []
    parts << (load_value.present? ? "#{reps_completed} × #{fmt(load_value)} #{load_unit}" : reps_completed.to_s)
    parts << "RPE #{fmt(rpe_reported)}" if rpe_reported.present?
    parts.compact_blank.join(" · ")
  end

  private

  def fmt(number) = number.to_d.to_s("F").sub(/\.0+$/, "")

  def substitution_is_acceptable
    return if block_exercise.blank? || exercise_id.blank?
    return if block_exercise.acceptable_exercises.map(&:id).include?(exercise_id)

    errors.add(:exercise_id, :not_an_accepted_substitution)
  end
end
