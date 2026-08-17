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
    raise ActiveRecord::RecordInvalid, self if program_weeks.empty?

    transaction do
      # Only one published version at a time -- an assignment pins a specific
      # version, so older ones stay readable but stop being the current one.
      program.program_versions.published.where.not(id: id).update_all(status: "archived")
      update!(status: "published", published_at: Time.current)
    end
  end

  def editable? = status == "draft"

  # Deep copy into a fresh draft. Used both to open an existing program for
  # editing and to fork a published version without disturbing anyone mid-plan.
  def duplicate_as_draft! = copy_to_program!(program, status: "draft")

  # Deep copy into any program, not just this one -- which is what makes
  # template assignment possible without a second copy implementation.
  def copy_to_program!(target, status: "draft")
    transaction do
      copy = target.program_versions.create!(
        status: status,
        duration_weeks: duration_weeks,
        source_import_id: source_import_id
      )
      program_weeks.order(:position).each { |week| week.copy_into!(copy) }
      copy
    end
  end

  def summary
    { weeks: program_weeks.count, days: ProgramDay.where(program_week: program_weeks).count }
  end

  private

  def assign_version_number
    return if version_number.present? && version_number != 1
    self.version_number = (program&.program_versions&.maximum(:version_number) || 0) + 1
  end
end
