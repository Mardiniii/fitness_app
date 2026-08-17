# A direct port of the log table at the back of Cristian's 2026 plan:
# bodyweight, general feeling 1-10, average sleep hours, progress notes.
# Four fields, unchanged, because he already validated them in practice.
class CheckIn < ApplicationRecord
  belongs_to :client, class_name: "User", inverse_of: :check_ins
  belongs_to :program_assignment, optional: true

  validates :week_of, presence: true, uniqueness: { scope: :client_id }
  validates :feeling, numericality: {
    only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10
  }, allow_nil: true
  validates :bodyweight_kg, numericality: { greater_than: 0, less_than: 500 }, allow_nil: true
  validates :sleep_hours_avg, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 24
  }, allow_nil: true

  before_validation { self.week_of ||= Date.current.beginning_of_week }

  scope :recent, -> { order(week_of: :desc) }
end
