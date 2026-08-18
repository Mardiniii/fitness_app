# Answers one question, in one glance: am I lifting more than I was?
#
# Everything here is computed from set_logs -- what actually happened -- never
# from prescribed_sets. That separation is the reason the number can be
# trusted: a program edited last week cannot retroactively change what the
# client did in March.
class ProgressReport
  Point = Struct.new(:on, :best_load, :best_reps, :volume, :unit, keyword_init: true)

  Trend = Struct.new(:exercise, :points, :unit, keyword_init: true) do
    def first_point = points.first
    def last_point  = points.last
    def sessions    = points.size

    # Percent change in best load between the first and last session that
    # carried one. Nil rather than zero when there is nothing to compare, so
    # the view can say "one session" instead of implying no progress.
    def change_pct
      return nil if points.size < 2

      from = points.first.best_load
      to   = points.last.best_load
      return nil if from.nil? || to.nil? || from.zero?

      (((to - from) / from) * 100).round
    end
  end

  def initialize(client:, weeks: 12)
    @client = client
    @since  = weeks.weeks.ago.beginning_of_week.to_date
  end

  attr_reader :client, :since

  # Per-exercise load over time, heaviest movements first, so the lifts the
  # client cares about are not buried under warm-up mobility work.
  def exercise_trends(limit: 8)
    grouped = logs.group_by(&:exercise_id)

    trends = grouped.filter_map do |_exercise_id, rows|
      points = points_for(rows)
      next if points.empty?

      Trend.new(exercise: rows.first.exercise, points: points, unit: points.last.unit)
    end

    trends.sort_by { |t| -(t.last_point.best_load || 0) }.first(limit)
  end

  # Sessions completed per week. The honest denominator is "did you train",
  # not "did you finish every prescribed set", so this counts sessions.
  def session_history(weeks: 8)
    done = client.program_assignments
                 .joins(:sessions)
                 .where(sessions: { status: "completed" })
                 .where(sessions: { completed_at: weeks.weeks.ago.. })
                 .pluck(Arel.sql("sessions.completed_at"))

    tally = done.compact.group_by { |at| at.to_date.beginning_of_week }
                .transform_values(&:size)

    week_starts(weeks).map { |week| { week_of: week, sessions: tally.fetch(week, 0) } }
  end

  def check_in_trend
    client.check_ins.where(week_of: since..).order(:week_of).to_a
  end

  def any_data? = logs.any? || check_in_trend.any?

  private

  # One best set per exercise per session: the heaviest load, and the volume
  # actually moved. per_side doubles the reps, because "15 remo por brazo"
  # means fifteen on each arm.
  def points_for(rows)
    rows.group_by(&:session_id).filter_map do |_session_id, session_rows|
      on = session_rows.filter_map(&:completed_at).min&.to_date
      next if on.nil?

      loaded = session_rows.reject { |r| r.load_value.nil? }
      best   = loaded.max_by(&:load_value)

      volume = session_rows.sum do |r|
        next 0 if r.reps_completed.nil? || r.load_value.nil?
        r.reps_completed * (r.block_exercise&.per_side? ? 2 : 1) * r.load_value
      end

      Point.new(on: on, best_load: best&.load_value, best_reps: best&.reps_completed,
                volume: volume, unit: best&.load_unit)
    end.sort_by(&:on)
  end

  def logs
    @logs ||= SetLog.done
                    .joins(session: :program_assignment)
                    .where(program_assignments: { client_id: client.id })
                    .where(completed_at: since..)
                    .includes(:exercise, :block_exercise)
                    .order(:completed_at)
                    .to_a
  end

  def week_starts(weeks)
    start = weeks.weeks.ago.to_date.beginning_of_week
    (0...weeks).map { |i| start + i.weeks }
  end
end
