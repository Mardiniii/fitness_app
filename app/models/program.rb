# Program identity only. All content lives in versions, so that editing never
# disturbs a client who is mid-way through an assigned copy.
class Program < ApplicationRecord
  belongs_to :practitioner, class_name: "User", inverse_of: :authored_programs

  has_many :program_versions, -> { order(version_number: :desc) }, dependent: :destroy

  validates :name, presence: true

  scope :kept, -> { where(discarded_at: nil) }

  def current_version = program_versions.published.first
  def draft_version   = program_versions.draft.first
end
