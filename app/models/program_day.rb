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

  # The order the client actually works in: depth-first through the block tree,
  # so a paired "bloque A + bloque B" yields A's exercises then B's rather than
  # every top-level slot first. The runner shows one of these per screen.
  def ordered_block_exercises
    program_blocks.flat_map { |block| walk_block(block) }
  end

  # A walkthrough of the whole session. Distinct from Exercise#video, which
  # explains a single movement.
  def video  = VideoLink.wrap(reference_url)
  def video? = reference_url.present?

  # Columns that belong to a specific row rather than to its content. Copying
  # works by "everything except these", so a new column is carried across by
  # default instead of being silently dropped -- which is exactly how
  # reference_url went missing the first time.
  COPY_EXCLUDED = %w[id program_week_id created_at updated_at].freeze

  def copy_into!(target_week)
    copy = target_week.program_days.create!(attributes.except(*COPY_EXCLUDED))
    # Top-level blocks only; each block copies its own children, so nested
    # "bloque A + bloque B" structures come across intact.
    program_blocks.order(:position).each { |block| block.copy_into!(day: copy) }
    copy
  end

  private

  def walk_block(block)
    block.block_exercises.to_a + block.child_blocks.flat_map { |child| walk_block(child) }
  end
end
