# Rebuilds the prescribed sets for one block exercise from editor params.
#
# Two authoring modes, because the real plans are overwhelmingly one shape with
# a handful of exceptions:
#
#   uniform  — "3 series · 6-8 · RPE 9 · 40lb · 2 min". One row of inputs,
#              expanded into N identical sets. This is the common case.
#   per_set  — the exceptions: "15-12-10 @ 15/20/25lb", "10-10-10 @ 25-30-35lb".
#              Each set edited independently, with an optional drop segment.
#
# Rebuilds rather than diffs: prescribed_sets have no children, and set_logs
# reference the block exercise (not the set), so replacing them cannot orphan a
# client's history.
class PrescriptionBuilder
  SET_FIELDS = %i[measure_kind reps_min reps_max work_seconds distance_value distance_unit
                  calories load_kind load_value load_value_max load_unit equipment_item_id
                  target_rpe rest_seconds notes].freeze

  def initialize(block_exercise, params)
    @block_exercise = block_exercise
    @params = params
  end

  def save!
    ActiveRecord::Base.transaction do
      @block_exercise.prescribed_sets.destroy_all
      uniform? ? build_uniform : build_per_set
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @error = e.record.errors.full_messages.to_sentence
    false
  end

  attr_reader :error

  private

  def uniform? = @params[:mode].to_s != "per_set"

  def set_count = @params[:set_count].to_i.clamp(1, 20)

  def build_uniform
    attrs = clean(@params[:uniform] || {})
    set_count.times do |i|
      @block_exercise.prescribed_sets.create!(attrs.merge(set_number: i + 1, segment_number: 1))
    end
  end

  def build_per_set
    rows = (@params[:sets] || {}).values
    rows.each_with_index do |row, i|
      base = clean(row)
      @block_exercise.prescribed_sets.create!(base.merge(set_number: i + 1, segment_number: 1))

      # "12+12" / "100lb + 10 con 70lb" -- a second segment inside the same set
      next if row[:drop_reps].blank?

      @block_exercise.prescribed_sets.create!(
        base.merge(set_number: i + 1, segment_number: 2,
                   reps_min: row[:drop_reps], reps_max: nil,
                   load_value: row[:drop_load].presence || base[:load_value])
      )
    end
  end

  # Blank strings would fail the measure-kind check constraint, so they become
  # nil and let the column defaults and constraints do their job.
  def clean(row)
    row.to_h.symbolize_keys.slice(*SET_FIELDS).transform_values { |v| v.presence }
       .tap { |h| h[:measure_kind] = h[:measure_kind].presence || "reps" }
       .tap { |h| h[:load_kind] = h[:load_kind].presence || "none" }
  end
end
