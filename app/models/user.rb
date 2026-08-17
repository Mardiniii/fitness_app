# One row per human, whatever their role. Deliberately NOT split into
# trainers/nutritionists/clients tables -- a person can be a practitioner and
# somebody else's client at the same time.
class User < ApplicationRecord
  # No :registerable -- clients never self-sign-up. A practitioner invites them,
  # which is how the product actually works and removes a whole attack surface.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  pg_enum :role, %w[practitioner client admin], validate: true
  pg_enum :unit_preference, %w[metric imperial], prefix: :units, validate: true

  has_one :practitioner_profile, dependent: :destroy
  has_one :client_profile,       dependent: :destroy

  # As a practitioner: the people I coach
  has_many :client_relationships, class_name: "PractitionerClient",
           foreign_key: :practitioner_id, inverse_of: :practitioner, dependent: :destroy
  has_many :clients, through: :client_relationships, source: :client

  # As a client: the people who coach me. Both directions exist so that
  # cross-practitioner visibility (trainer sees nutrition, and vice versa)
  # is a query rather than a schema change.
  has_many :practitioner_relationships, class_name: "PractitionerClient",
           foreign_key: :client_id, inverse_of: :client, dependent: :destroy
  has_many :practitioners, through: :practitioner_relationships, source: :practitioner

  has_many :program_assignments, foreign_key: :client_id, inverse_of: :client, dependent: :destroy
  has_many :authored_programs, class_name: "Program",
           foreign_key: :practitioner_id, inverse_of: :practitioner, dependent: :destroy
  has_many :check_ins, foreign_key: :client_id, inverse_of: :client, dependent: :destroy

  normalizes :email, with: ->(value) { value.to_s.strip }

  # email presence/format/uniqueness comes from Devise's :validatable
  validates :name, presence: true

  scope :kept, -> { where(discarded_at: nil) }

  def display_name = name.presence || email
end
