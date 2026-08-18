# Enough history that the app shows what it is for the moment you sign in.
#
# A fresh install with one empty week cannot demonstrate the product: the
# progress screen has nothing to draw, "la vez pasada" is blank on every set,
# and the roster cannot show who needs chasing. So this fills in a plausible
# few weeks per client.
#
# The three clients are deliberately at different stages. A roster where
# everyone looks the same proves nothing about the screen whose whole job is
# telling the practitioner where to look.
#
# The numbers are generated, not real. They trend the way a real block does --
# load creeping up, a bad week, a skipped set -- because a perfectly linear
# demo teaches you nothing about whether the charts read correctly.

PROFILES = [
  # email env, fallback, session offsets in days ago, check-in weeks, load wobble
  { env: "SEED_CLIENT_EMAIL",  email: "sebastian@fitfusion.local",
    days_ago: [ 35, 32, 28, 25, 21, 18, 14, 11, 7, 4 ], check_ins: 12, base: 1.00,
    skip_at: 5 },

  { env: "SEED_CLIENT2_EMAIL", email: "estefania@fitfusion.local",
    days_ago: [ 24, 21, 17, 14, 9, 2 ], check_ins: 8, base: 0.72, skip_at: nil },

  # Started, then dropped off twelve days ago. This is the row that should read
  # orange on the roster.
  { env: "SEED_CLIENT3_EMAIL", email: "katherine@fitfusion.local",
    days_ago: [ 26, 22, 19 ], check_ins: 4, base: 0.55, skip_at: 1 }
].freeze

# A deterministic wobble, so the demo looks lived-in but every machine gets the
# same database. Rand would make two installs disagree.
WOBBLE = [ 0.0, 0.02, -0.01, 0.03, 0.01, 0.04, -0.02, 0.05, 0.03, 0.06 ].freeze

BODYWEIGHT = [ 79.6, 79.4, 79.1, 78.9, 79.2, 78.6, 78.3, 78.4, 77.9, 77.5, 77.2, 76.9 ].freeze
FEELING    = [ 6, 6, 7, 7, 6, 7, 8, 7, 8, 8, 9, 8 ].freeze
SLEEP      = [ 6.2, 6.5, 6.5, 7.0, 6.0, 7.0, 7.2, 7.0, 7.5, 7.5, 7.8, 7.5 ].freeze
NOTES = {
  4  => "Semana pesada en el trabajo, dormí mal y se notó en la fuerza.",
  8  => "Volvió la energía. La sentadilla se sintió mucho más sólida.",
  11 => "Mejor semana del bloque. Subí carga sin perder técnica."
}.freeze

summary = []

PROFILES.each do |profile|
  client = User.find_by(email: ENV.fetch(profile[:env], profile[:email]))
  assignment = client&.program_assignments&.order(:starts_on)&.last
  next if assignment.nil?

  days = assignment.program_version.program_weeks.order(:position)
                   .flat_map { |week| week.program_days.order(:position).to_a }

  profile[:days_ago].each_with_index do |days_ago, index|
    day = days[index]
    next if day.nil?

    at = days_ago.days.ago.change(hour: 7, min: 15)

    session = assignment.sessions.create!(
      program_day: day,
      status: "completed",
      started_at: at,
      completed_at: at + (52 + index).minutes,
      duration_seconds: (52 + index) * 60,
      overall_rpe: (7.5 + (index % 4) * 0.5).round(1)
    )

    # Each client lifts at their own level, and each of their sessions creeps
    # up a little, so every progress chart has a direction rather than a line.
    factor = profile[:base] * (1 + WOBBLE[index % WOBBLE.size])
    skipped_this_session = false

    ProgramBlock.where(program_day: day)
                .includes(block_exercises: :prescribed_sets)
                .flat_map(&:block_exercises).each do |block_exercise|
      block_exercise.prescribed_sets.each do |prescribed|
        # One skipped set in one session per client: enough to prove the state
        # renders and that it stays out of the counts.
        skip_this = profile[:skip_at] == index && prescribed.set_number == 3 && !skipped_this_session
        skipped_this_session ||= skip_this

        load_value =
          if prescribed.load_value
            # Round to the nearest half, the way real plates and dumbbells go.
            [ ((prescribed.load_value * factor) * 2).round / 2.0, 2.5 ].max
          end

        session.set_logs.create!(
          block_exercise: block_exercise,
          exercise_id: block_exercise.exercise_id,
          set_number: prescribed.set_number,
          segment_number: prescribed.segment_number,
          reps_completed: skip_this ? nil : (prescribed.reps_max || prescribed.reps_min),
          duration_seconds: prescribed.work_seconds,
          load_value: skip_this ? nil : load_value,
          load_unit: (load_value && !skip_this) ? (prescribed.load_unit || "lb") : nil,
          rpe_reported: skip_this ? nil : prescribed.target_rpe,
          skipped: skip_this,
          completed_at: at + (10 + prescribed.set_number).minutes
        )
      end
    end
  end

  profile[:check_ins].times do |i|
    weeks_ago = profile[:check_ins] - 1 - i
    CheckIn.create!(
      client: client,
      program_assignment: assignment,
      week_of: weeks_ago.weeks.ago.to_date.beginning_of_week,
      bodyweight_kg: (BODYWEIGHT[i % BODYWEIGHT.size] * profile[:base].clamp(0.85, 1.0)).round(1),
      feeling: FEELING[i % FEELING.size],
      sleep_hours_avg: SLEEP[i % SLEEP.size],
      notes: NOTES[i]
    )
  end

  logged = SetLog.joins(:session).where(sessions: { program_assignment_id: assignment.id })
  summary << "    #{client.name}: #{assignment.sessions.count}/#{days.size} sesiones · " \
             "#{logged.where(skipped: false).count} series · " \
             "#{CheckIn.where(client: client).count} reportes"
end

puts "  history:"
puts summary.join("\n")
