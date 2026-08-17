class ClientInjury < ApplicationRecord
  belongs_to :client_profile

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
