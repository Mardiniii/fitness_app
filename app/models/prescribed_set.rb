# One row per set. Sets are NOT homogeneous -- "15-12-10 Bench press barra
# 15/20/25lb" is three distinct rows. segment_number > 1 carries drop sets:
# "10 extension de rodilla en maquina 100lb + 10 con 70lb" is one set, two
# segments. Enum prefixes are mandatory here: an unprefixed load_kind "none"
# would override ActiveRecord::Base.none.
class PrescribedSet < ApplicationRecord
  pg_enum :measure_kind,  %w[reps time distance calories],          prefix: :measure, validate: true
  pg_enum :load_kind,     %w[none bodyweight external band machine], prefix: :load,    validate: true
  pg_enum :load_unit,     %w[lb kg],   prefix: true, validate: true
  pg_enum :distance_unit, %w[m km mi], prefix: true, validate: true

  belongs_to :block_exercise
  belongs_to :equipment_item, optional: true

  validates :set_number,     presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :segment_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :set_number, uniqueness: { scope: %i[block_exercise_id segment_number] }
  validates :target_rpe, numericality: {
    greater_than_or_equal_to: 1, less_than_or_equal_to: 10
  }, allow_nil: true
  validate :measure_columns_present

  def drop_segment? = segment_number > 1

  # "12", "10-12", "3 min", "300 m", "12 cal"
  def prescription_summary
    case measure_kind
    when "reps"     then reps_max && reps_max != reps_min ? "#{reps_min}-#{reps_max}" : reps_min.to_s
    when "time"     then "#{work_seconds}s"
    when "distance" then "#{distance_value.to_i} #{distance_unit}"
    when "calories" then "#{calories} cal"
    end
  end

  # "20 lb", "20/25 lb", "power band verde", "bodyweight"
  def load_summary
    case load_kind
    when "none"       then nil
    when "bodyweight" then "bodyweight"
    when "band"       then equipment_item&.display_name
    else
      return equipment_item&.display_name if load_value.blank?
      value = load_value_max.present? ? "#{fmt(load_value)}/#{fmt(load_value_max)}" : fmt(load_value)
      "#{value} #{load_unit}"
    end
  end

  private

  def fmt(number) = number.to_d.to_s("F").sub(/\.0+$/, "")

  # Mirrors the DB check constraint so the user gets a message rather than a
  # PG::CheckViolation when the import parser produces something incoherent.
  def measure_columns_present
    required = { "reps" => reps_min, "time" => work_seconds,
                 "distance" => distance_value, "calories" => calories }[measure_kind]
    errors.add(:base, :measure_value_missing, kind: measure_kind) if required.nil?
  end
end
