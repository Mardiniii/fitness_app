# SEMANA 1 of the plan Sebastian is currently on.
# Transcribed from "PLAN DE ENTRENAMIENTO PERSONALIZADO", Cliente: Sebastian
# Zapata, Coach: Cristian Franco, Fecha de Inicio 07/07/2026.
#
# This generation prescribes flat tables rather than bloques, so each day is
# modelled as two blocks: the mobility rows (short rest, no RPE) and the
# working rows. It covers, from the real document:
#   - per-set load variation   "10-10-10" @ "25-30-35lb"
#   - an explicit drop set     "12+12"    (Drop set en sentadilla bulgara)
#   - rep ranges               "6-8", "10-12" @ "35-40lb"
#   - half-point RPE           "RPE 8.5"
#   - time-based work          "30 seg" in the repetitions column
#   - per-side prescriptions   "por pierna", "por brazo"
#
# Idempotent: the draft is rebuilt each run.

practitioner = User.find_by!(email: ENV.fetch("SEED_TRAINER_EMAIL", "cristian@fitfusion.local"))

REST = { "8 seg" => 8, "10 seg" => 10, "20 seg" => 20, "30 seg" => 30, "60 seg" => 60,
         "90 seg" => 90, "1 min" => 60, "1min" => 60, "2 min" => 120, "3 min" => 180 }.freeze

# Rows in the current plan that are not yet in the library get created here,
# unconfirmed, exactly like the PDF-derived ones.
def ex!(name)
  Exercise.find_by(name_es: name) ||
    Exercise.create!(name_es: name, muscle_region: "full_body",
                     movement_structure: "compuesto", default_measure_kind: "reps",
                     taxonomy_confirmed: false)
end

W = "Calentamiento".freeze
M = "Parte principal".freeze

DAYS = [
  { n: 1, focus: "PIERNA (ENFOQUE CUÁDRICEPS) + CORE",
    note: "Enfocado en fuerza de tren inferior y fortalecimiento de zona media",
    rows: [
    [ W, "Liberacion posterior sentado en carrizo",       { reps: 12, rest: "8 seg", note: "Lleva manos a talon" } ],
    [ W, "Rotacion de cadera acostado boca arriba",       { reps: 10, rest: "8 seg", note: "Lleva rodillas al piso" } ],
    [ W, "Superman dinamico",                             { reps: 15, rest: "8 seg", note: "Toca mano y rodilla contraria" } ],
    [ W, "Empuje de cadera con pie sobre inestable",      { reps: 15, rest: "1 min", note: "Apoyo en el talon" } ],
    [ M, "Sentadilla sumo con mancuernas en hombros",     { reps: 10, rest: "3 min", rpe: 9, load: 40, note: "Punta de pies hacia afuera" } ],
    [ M, "Sentadilla sumo con 1 mancuerna abajo en rebote", { reps: 20, rest: "2 min", rpe: 9, load: 40, note: "Movimiento incompleto" } ],
    [ M, "Tijera estatica por pierna",                    { reps: 12, rest: "1 min", rpe: 8, load: 35, per_side: true, note: "Buen apoyo en punta de pie atras" } ],
    [ M, "Elevacion de talon con mancuernas",             { reps: 30, rest: "1 min", rpe: 9, load: 40, note: "Pies sobre cojin" } ],
    [ M, "Plancha tipo carpa",                            { reps: 12, rest: "30 seg", rpe: 8, note: "Con deslizadores" } ],
    [ M, "Dead bug con power band Negra",                 { reps: 16, rest: "30 seg", rpe: 8, note: "Elastico desde rack" } ] ] },

  { n: 2, focus: "TORSO (EMPUJE Y TRACCIÓN)",
    note: "Desarrollo balanceado de pecho, espalda y hombros.",
    rows: [
    [ W, "Rotacion alternada de tronco en rodillas",      { reps: 10, rest: "20 seg", note: "Lleva brazo arriba" } ],
    [ W, "Liberacion escapular en rodillas",              { reps: 10, rest: "20 seg", note: "Lleva hombro a piso" } ],
    [ W, "Rotacion completa de hombros con power band roja", { reps: 15, rest: "20 seg", note: "elastico en tension" } ],
    # "10-10-10" at "25-30-35lb": three sets, three loads
    [ M, "Aproximaciones bench press",                    { scheme: [ [ 10, 25 ], [ 10, 30 ], [ 10, 35 ] ], rest: "30 seg", rpe: 6, note: "3 pesos diferentes de menor a mayor" } ],
    [ M, "Press de Banca con mancuernas",                 { reps: 10, rest: "3 min", rpe: 9, load: 50, note: "Sin juntar mancuernas arriba" } ],
    [ M, "Remo con mancuerna por brazo",                  { reps: 12, rest: "2 min", rpe: 8, load: 50, per_side: true, note: "Llevar mancuerna a la pelvis." } ],
    [ M, "Aperturas en banco plano",                      { reps: 15, rest: "2 min", rpe: 8, load: 30, note: "Codos con ligera flexion" } ],
    [ M, "Remo sentado en piso con power verde y negra",  { reps: 15, rest: "90 seg", rpe: 8.5, note: "Elasticos hacia abdomen" } ],
    [ M, "Abd hombro de pie con apoyo en banco",          { reps: 15, rest: "60 seg", rpe: 9, load: 15, note: "Pecho apoyado en banco" } ],
    [ M, "Curl de biceps tipo predicador en supino",      { reps: 12, rest: "60 seg", rpe: 8, load: 20, note: "Apoyado en banco" } ],
    [ M, "Copa por brazo",                                { reps: 12, rest: "60 seg", rpe: 9, load: 20, per_side: true, note: "Sentado en banco" } ] ] },

  { n: 3, focus: "PIERNA (ENFOQUE EN POSTERIOR) + CORE",
    note: "Enfocado en fuerza base y desarrollo del tren inferior.",
    rows: [
    [ W, "Liberacion miofacial gluteo con foller",        { reps: 10, rest: "8 seg", note: "Sentado sobre foller" } ],
    [ W, "Plancha en manos cruzando pierna",              { reps: 10, rest: "8 seg", note: "Liberacion glutea" } ],
    [ W, "Flexion rodilla con fitball por pierna",        { reps: 10, rest: "8 seg", per_side: true, note: "Talon sobre fitball" } ],
    [ W, "Tijera estatica sobre inestable",               { reps: 10, rest: "30 seg", note: "Punta de pie atras firme" } ],
    [ M, "Peso muerto con power band morada desde rack",  { reps: 12, rest: "2 min", rpe: 9, load: 40, note: "Mancuernas laterales" } ],
    # "12+12" -- one set, two segments
    [ M, "Drop set en sentadilla bulgara",                { reps: 12, drop: 12, rest: "2 min", rpe: 9, load: 40, note: "Mancuerna del lado contrario" } ],
    [ M, "Elevacion de talon por pierna",                 { reps: 15, rest: "1 min", rpe: 9, load: 40, per_side: true, note: "Sobre escala" } ],
    [ M, "Plancha sostenida sobre fitball",               { seconds: 30, rest: "20 seg", rpe: 8, note: "Piernas separadas" } ],
    [ M, "Plancha deslizando atras",                      { reps: 12, rest: "20 seg", rpe: 8, note: "Pies sobre deslizadores" } ],
    [ M, "Superman sostenido",                            { seconds: 30, rest: "1 min", rpe: 8, note: "Brazo y pierna alineados" } ] ] },

  { n: 4, focus: "TORSO (EMPUJE Y TRACCIÓN)",
    note: "Desarrollo balanceado de pecho, espalda y hombros.",
    rows: [
    [ W, "Encogimiento de hombro por brazo con power band morada", { reps: 15, rest: "10 seg", per_side: true, note: "Brazo extendido" } ],
    [ W, "Rotacion completa de hombro con power band roja", { reps: 15, rest: "10 seg", note: "Elastico tensionado" } ],
    [ W, "Aperturas con power band roja",                 { reps: 15, rest: "10 seg", note: "Brazos extendidos al frente" } ],
    # "10-12" reps at "35-40lb": a range on both axes
    [ M, "Remo apoyado en banco con power morada por brazo", { reps_min: 10, reps_max: 12, rest: "3 min", rpe: 8, load: 35, load_max: 40, per_side: true, note: "Pecho contra el banco" } ],
    [ M, "Pull over",                                     { reps: 12, rest: "2 min", rpe: 9, load: 40, note: "Brazos extendidos" } ],
    [ M, "Press banco inclinado con mancuernas",          { reps_min: 6, reps_max: 8, rest: "3 min", rpe: 9, load: 40, note: "Rango de movimiento completo" } ],
    [ M, "Push up con apoyo por brazo en mancuerna",      { reps: 10, rest: "1 min", rpe: 8.5, per_side: true, note: "Una mano en mancuerna la otra en piso" } ],
    [ M, "Abd hombro inclinado en la pared",              { reps: 15, rest: "60 seg", rpe: 9, load: 15, note: "Cuerpo inclinado" } ],
    [ M, "Curl de biceps alternado der-izq-ambas",        { reps: 21, rest: "60 seg", rpe: 8, load: 20, note: "Con rotacion" } ],
    [ M, "Patada de triceps con power band Negra por brazo", { reps: 15, rest: "60 seg", rpe: 9, load: 20, per_side: true, note: "Power band desde el rack" } ] ] }
].freeze

program = Program.find_or_create_by!(practitioner: practitioner,
                                     name: "Hipertrofia / Pérdida de grasa") do |p|
  p.goal = "Hipertrofia / Pérdida de grasa"
  p.description = "Plan real de Cristian Franco. Inicio 07/07/2026."
end

program.program_versions.draft.destroy_all
version = program.program_versions.create!(status: "draft", duration_weeks: 4)
week = version.program_weeks.create!(position: 1, name: "SEMANA 1")

DAYS.each do |d|
  day = week.program_days.create!(position: d[:n], name: "DÍA #{d[:n]}",
                                  focus: d[:focus], description: d[:note])

  d[:rows].group_by(&:first).each_with_index do |(block_name, rows), bi|
    block = day.program_blocks.create!(
      position: bi + 1, name: block_name,
      execution_mode: "straight_sets", round_count: 3
    )

    rows.each_with_index do |(_, name, o), ei|
      be = block.block_exercises.create!(
        exercise: ex!(name), position: ei + 1,
        per_side: o[:per_side] || false, technique_notes: o[:note]
      )

      rest = REST.fetch(o[:rest], nil)
      base = { rest_seconds: rest, target_rpe: o[:rpe], load_unit: (o[:load] ? "lb" : nil),
               load_kind: (o[:load] ? "external" : "bodyweight") }

      if o[:scheme] # per-set load variation
        o[:scheme].each_with_index do |(reps, load), si|
          be.prescribed_sets.create!(base.merge(
            set_number: si + 1, measure_kind: "reps", reps_min: reps,
            load_kind: "external", load_value: load, load_unit: "lb"))
        end
      elsif o[:seconds] # a hold
        3.times { |si| be.prescribed_sets.create!(base.merge(
          set_number: si + 1, measure_kind: "time", work_seconds: o[:seconds])) }
      else
        3.times do |si|
          be.prescribed_sets.create!(base.merge(
            set_number: si + 1, segment_number: 1, measure_kind: "reps",
            reps_min: o[:reps_min] || o[:reps], reps_max: o[:reps_max],
            load_value: o[:load], load_value_max: o[:load_max]))
          # "12+12": a second segment inside the same set
          next unless o[:drop]

          be.prescribed_sets.create!(base.merge(
            set_number: si + 1, segment_number: 2, measure_kind: "reps",
            reps_min: o[:drop], load_value: o[:load]))
        end
      end
    end
  end
end

# Weeks 2-4: the same structure, progressively heavier.
#
# Honest about what this is -- SEMANA 1 above is transcribed from the real
# document; these three are generated from it by bumping the load. The later
# SEMANA PDFs exist and will replace this when the import lands. Until then a
# single week gives the progress screens nothing to draw, and a product whose
# whole claim is "am I lifting more than six weeks ago" has to be able to show
# six weeks on a fresh install.
PROGRESSION = { 2 => 1.05, 3 => 1.10, 4 => 1.15 }.freeze

PROGRESSION.each do |position, factor|
  later = version.program_weeks.create!(position: position, name: "SEMANA #{position}")
  week.program_days.order(:position).each { |day| day.copy_into!(later) }

  # update_columns rather than update!: these rows are already valid, and the
  # measure-kind check constraint has nothing to say about a load change.
  PrescribedSet.joins(block_exercise: { program_block: :program_day })
               .where(program_days: { program_week_id: later.id })
               .where.not(load_value: nil)
               .find_each do |prescribed|
    prescribed.update_columns(
      load_value: (prescribed.load_value * factor).round(1),
      load_value_max: prescribed.load_value_max && (prescribed.load_value_max * factor).round(1)
    )
  end
end

# Publish and assign once. Re-running refreshes the draft but never touches an
# existing published version, because an assignment pins one and a client's
# logged sessions hang off it.
# Everybody gets the same block, starting on a different date -- which is what
# actually happens: Cristian writes one plan and rolls clients onto it as they
# come in. The roster is only interesting because they are at different points.
assignees = [
  [ ENV.fetch("SEED_CLIENT_EMAIL",  "sebastian@fitfusion.local"), Date.new(2026, 7, 7) ],
  [ ENV.fetch("SEED_CLIENT2_EMAIL", "estefania@fitfusion.local"), Date.new(2026, 7, 14) ],
  [ ENV.fetch("SEED_CLIENT3_EMAIL", "katherine@fitfusion.local"), Date.new(2026, 7, 21) ]
].filter_map { |email, starts_on| [ User.find_by(email: email), starts_on ] if User.exists?(email: email) }

if program.published_version.nil? && assignees.any?
  version.publish!
  assignees.each { |user, starts_on| program.assign_to!(client: user, starts_on: starts_on) }
  state = "publicada v#{program.published_version.version_number} y asignada a " \
          "#{assignees.map { |u, _| u.name }.join(', ')}"
elsif assignees.any?
  state = "ya publicada y asignada; borrador actualizado"
else
  state = "sin clientes para asignar"
end

all_days = ProgramDay.where(program_week: version.program_weeks)
sets = PrescribedSet.joins(block_exercise: :program_block)
                    .where(program_blocks: { program_day_id: all_days.select(:id) })
puts "  sample program: #{program.name} (4 semanas, inicio 07/07/2026)"
puts "    #{version.program_weeks.count} semanas · #{all_days.count} días · " \
     "#{ProgramBlock.where(program_day: all_days).count} bloques · " \
     "#{sets.count} series prescritas · #{sets.where('segment_number > 1').count} segmento(s) de drop set"
puts "    #{state}"
