class PractitionerProfile < ApplicationRecord
  pg_enum :specialty, %w[trainer nutritionist], validate: true

  belongs_to :user

  validates :user_id, uniqueness: true
end
