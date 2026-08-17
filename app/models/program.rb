# Program identity only. All content lives in versions, so that editing never
# disturbs a client who is mid-way through an assigned copy.
class Program < ApplicationRecord
  belongs_to :practitioner, class_name: "User", inverse_of: :authored_programs

  has_many :program_versions, -> { order(version_number: :desc) }, dependent: :destroy

  validates :name, presence: true

  scope :kept, -> { where(discarded_at: nil) }

  # At most one draft is editable at a time; published versions are frozen
  # because assignments point at them.
  def draft_version     = program_versions.draft.order(version_number: :desc).first
  def published_version = program_versions.published.order(version_number: :desc).first
  def latest_version    = program_versions.order(version_number: :desc).first

  # Opens an editable draft. Copies the newest published version when there is
  # one, so editing an existing program starts from its content rather than a
  # blank page.
  def open_draft!
    draft_version || published_version&.duplicate_as_draft! ||
      program_versions.create!(status: "draft")
  end
end
