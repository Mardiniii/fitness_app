# A "Bloque" in Cristian's plans. execution_mode is a field rather than an
# inference because he labels it himself in the source documents:
#   "3 series por ejercicio"  -> straight_sets
#   "3 series en circuito"    -> circuit
#   "4 series por tiempo 30\"x10\"" -> interval  (work 30, rest 10)
#   "1 serie = bloque A + bloque B" -> paired, via parent_block_id
class ProgramBlock < ApplicationRecord
  pg_enum :execution_mode, %w[straight_sets circuit interval paired], validate: true

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
  def nested?   = parent_block_id.present?

  private

  def parent_is_not_self
    errors.add(:parent_block_id, :cannot_nest_in_self) if parent_block_id.present? && parent_block_id == id
  end
end
