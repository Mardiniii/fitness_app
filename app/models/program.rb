# Program identity only. All content lives in versions, so that editing never
# disturbs a client who is mid-way through an assigned copy.
class Program < ApplicationRecord
  belongs_to :practitioner, class_name: "User", inverse_of: :authored_programs
  belongs_to :source_program, class_name: "Program", optional: true, inverse_of: :derived_programs

  has_many :derived_programs, class_name: "Program", foreign_key: :source_program_id,
           inverse_of: :source_program, dependent: :nullify
  has_many :program_versions, -> { order(version_number: :desc) }, dependent: :destroy
  has_many :program_assignments, through: :program_versions

  validates :name, presence: true

  scope :kept,      -> { where(discarded_at: nil) }
  scope :templates, -> { where(template: true) }
  scope :for_clients, -> { where(template: false) }

  # At most one draft is editable at a time; published versions are frozen
  # because assignments point at them.
  def draft_version     = program_versions.draft.order(version_number: :desc).first
  def published_version = program_versions.published.order(version_number: :desc).first
  def latest_version    = program_versions.order(version_number: :desc).first

  # Assigning a template produces a client-specific copy; assigning an ordinary
  # program hands over its published version directly. Either way the
  # assignment pins a frozen version, so nothing shifts under the client.
  def assign_to!(client:, starts_on: Date.current)
    source = published_version
    raise ActiveRecord::RecordInvalid, self if source.nil?

    transaction do
      version = template? ? clone_for(client, source) : source

      ProgramAssignment.create!(
        program_version: version, client: client,
        practitioner: practitioner, starts_on: starts_on
      )
    end
  end

  def assignable? = published_version.present?

  # Opens an editable draft. Copies the newest published version when there is
  # one, so editing an existing program starts from its content rather than a
  # blank page.
  def open_draft!
    draft_version || published_version&.duplicate_as_draft! ||
      program_versions.create!(status: "draft")
  end

  private

  def clone_for(client, source)
    copy = practitioner.authored_programs.create!(
      name: "#{name} · #{client.display_name}", goal: goal, description: description,
      template: false, source_program: self
    )
    version = source.copy_to_program!(copy, status: "published")
    version.update!(published_at: Time.current)
    version
  end
end
