# One exercise slot inside a block, with its prescription and the coaching note
# that belongs on the set-logging screen rather than buried in a detail view.
class BlockExercise < ApplicationRecord
  belongs_to :program_block
  belongs_to :exercise

  has_many :prescribed_sets, -> { order(:set_number, :segment_number) }, dependent: :destroy
  has_many :block_exercise_alternatives, -> { order(:position) }, dependent: :destroy
  has_many :alternative_exercises, through: :block_exercise_alternatives, source: :exercise
  has_many :set_logs, dependent: :destroy

  validates :position, presence: true, numericality: { only_integer: true }

  # Every exercise the client is allowed to perform for this slot -- the
  # prescribed one first, then the stated substitutions.
  def acceptable_exercises = [ exercise, *alternative_exercises ]

  # Sets grouped for display: [[set 1 segments], [set 2 segments], ...]
  # A drop set is a single set_number carrying more than one segment.
  def sets_by_number = prescribed_sets.group_by(&:set_number).values
end
