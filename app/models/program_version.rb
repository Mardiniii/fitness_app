# A frozen snapshot of program content. Assignments pin a version, which is the
# answer to "what happens when a practitioner edits a program a client is
# half-way through?" -- nothing, until they explicitly push the new version.
class ProgramVersion < ApplicationRecord
  pg_enum :status, %w[draft published archived], validate: true

  belongs_to :program
  belongs_to :source_import, class_name: "PlanImport", optional: true

  has_many :program_weeks, -> { order(:position) }, dependent: :destroy
  has_many :program_assignments, dependent: :restrict_with_error

  validates :version_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :program_id }

  before_validation :assign_version_number, on: :create

  def publish!
    update!(status: "published", published_at: Time.current)
  end

  private

  def assign_version_number
    return if version_number.present? && version_number != 1
    self.version_number = (program&.program_versions&.maximum(:version_number) || 0) + 1
  end
end
