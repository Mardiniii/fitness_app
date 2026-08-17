# A "Bloque" in Cristian's plans. execution_mode is a field rather than an
# inference because he labels it himself in the source documents:
#   "3 series por ejercicio"  -> straight_sets
#   "3 series en circuito"    -> circuit
#   "4 series por tiempo 30\"x10\"" -> interval  (work 30, rest 10)
#   "1 serie = bloque A + bloque B" -> paired, via parent_block_id
class ProgramBlock < ApplicationRecord
  pg_enum :execution_mode, %w[straight_sets circuit interval paired biseries], validate: true

  belongs_to :program_day
  belongs_to :parent_block, class_name: "ProgramBlock", optional: true,
             inverse_of: :child_blocks

  has_many :child_blocks, -> { order(:position) }, class_name: "ProgramBlock",
           foreign_key: :parent_block_id, inverse_of: :parent_block, dependent: :destroy
  has_many :block_exercises, -> { order(:position) }, dependent: :destroy

  validates :position, presence: true, numericality: { only_integer: true }
  validate  :parent_is_not_self

  scope :roots, -> { where(parent_block_id: nil) }

  def interval? = execution_mode == "interval"

  # Recursive: a block copies its child blocks, its exercises, each exercise's
  # prescribed sets, and the stated substitutions.
  def copy_into!(day: nil, parent: nil)
    copy = ProgramBlock.create!(
      program_day: day || parent.program_day,
      parent_block: parent,
      position: position, name: name, focus: focus,
      execution_mode: execution_mode, round_count: round_count,
      work_seconds: work_seconds, rest_seconds: rest_seconds,
      rest_between_rounds_seconds: rest_between_rounds_seconds, notes: notes
    )

    block_exercises.order(:position).each do |be|
      be_copy = copy.block_exercises.create!(
        exercise_id: be.exercise_id, position: be.position,
        per_side: be.per_side, technique_notes: be.technique_notes
      )
      be.prescribed_sets.order(:set_number, :segment_number).each do |ps|
        be_copy.prescribed_sets.create!(ps.attributes.except("id", "block_exercise_id", "created_at", "updated_at"))
      end
      be.block_exercise_alternatives.order(:position).each do |alt|
        be_copy.block_exercise_alternatives.create!(
          exercise_id: alt.exercise_id, position: alt.position, note: alt.note
        )
      end
    end

    child_blocks.order(:position).each { |child| child.copy_into!(parent: copy) }
    copy
  end
  def nested?   = parent_block_id.present?

  private

  def parent_is_not_self
    errors.add(:parent_block_id, :cannot_nest_in_self) if parent_block_id.present? && parent_block_id == id
  end
end
