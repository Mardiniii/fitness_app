# Audit trail for the plan importer. source_text is kept permanently: it is the
# regression corpus for the parser, and the record of what a program was built
# from when it looks wrong six months later.
class PlanImport < ApplicationRecord
  pg_enum :source_type, %w[paste pdf], prefix: :source, validate: true
  # prefix is mandatory here: the value "committed" would otherwise generate
  # committed!, which ActiveRecord::Transactions already defines. Same failure
  # family as load_kind's "none" clobbering ActiveRecord::Base.none.
  pg_enum :status, %w[pending parsed review committed failed], prefix: true, validate: true

  belongs_to :practitioner, class_name: "User"
  belongs_to :program_version, optional: true

  has_many :produced_versions, class_name: "ProgramVersion",
           foreign_key: :source_import_id, inverse_of: :source_import, dependent: :nullify

  validates :source_text, presence: true, if: :source_paste?

  scope :awaiting_review, -> { where(status: "review") }

  def flagged_fields = confidence_flags.fetch("low_confidence", [])
end
