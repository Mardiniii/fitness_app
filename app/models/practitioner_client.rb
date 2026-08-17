# The practitioner <-> client relationship. A plain join, on purpose: a client
# may hold one row for their trainer and another for their nutritionist.
class PractitionerClient < ApplicationRecord
  pg_enum :relationship_type, %w[trainer nutritionist], prefix: :relationship, validate: true
  pg_enum :status, %w[invited active paused ended], validate: true

  belongs_to :practitioner, class_name: "User", inverse_of: :client_relationships
  belongs_to :client,       class_name: "User", inverse_of: :practitioner_relationships

  validates :practitioner_id, uniqueness: { scope: %i[client_id relationship_type] }
  validate  :practitioner_is_not_client

  private

  def practitioner_is_not_client
    errors.add(:client_id, :cannot_coach_self) if practitioner_id.present? && practitioner_id == client_id
  end
end
