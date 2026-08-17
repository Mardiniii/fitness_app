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

  private

  def substitution_is_acceptable
    return if block_exercise.blank? || exercise_id.blank?
    return if block_exercise.acceptable_exercises.map(&:id).include?(exercise_id)

    errors.add(:exercise_id, :not_an_accepted_substitution)
  end
end
