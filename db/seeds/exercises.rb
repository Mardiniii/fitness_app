# Exercise library, extracted from four generations of Cristian Franco's real
# plans (2025 block-based and 2026 RPE-based, ~430 prescribed lines).
#
# Classification follows HIS four axes, from his own sheet:
#   region    : tren_inferior | tren_superior | full_body
#   structure : aislado | compuesto
#   quality   : aceleracion | fuerza
#   purpose   : movilidad | fortaleza
#
# Everything seeded here is taxonomy_confirmed: false. These are our readings
# of his documents, not his sign-off -- he confirms them in the app.
#
# Columns: name, region, structure, quality, purpose, measure, equipment, cue

LI, LS, FB = "tren_inferior", "tren_superior", "full_body"
AIS, COM   = "aislado", "compuesto"
ACE, FUE   = "aceleracion", "fuerza"
MOV, FOR   = "movilidad", "fortaleza"

EXERCISES = [
  # ---------------- SENTADILLA / DOMINANTE DE RODILLA ----------------
  [ "Sentadilla con barra libre",              LI, COM, FUE, FOR, "reps", "Barra libre" ],
  [ "Sentadilla en Smith",                     LI, COM, FUE, FOR, "reps", "Smith" ],
  [ "Globet squat",                            LI, COM, FUE, FOR, "reps", "Kettlebell", "Talones activos" ],
  [ "Sentadilla sumo con mancuernas en hombros", LI, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Sentadilla búlgara",                      LI, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Búlgara con pie delantero sobre step",    LI, COM, FUE, FOR, "reps", "Step" ],
  [ "Sentadilla OH con power band",            LI, COM, FUE, FOR, "reps", "Power band roja" ],
  [ "Sentadilla sostenida elevando talones",   LI, COM, FUE, MOV, "time", "Peso corporal" ],
  [ "Sentadilla sostenida + apertura controlada", LI, COM, FUE, MOV, "reps", "Peso corporal" ],
  [ "Sentadilla + remo con power band",        FB, COM, FUE, FOR, "reps", "Power band verde" ],
  [ "Swing squat con mancuernas",              FB, COM, ACE, FOR, "reps", "Mancuernas" ],
  [ "Sentadilla de activación llevando brazos arriba", LI, COM, FUE, MOV, "reps", "Peso corporal" ],
  [ "Sentadilla con salto a step bajo",        LI, COM, ACE, FOR, "reps", "Step", "Cadera siempre abajo" ],
  [ "Desplazamiento en sentadilla sostenida",  LI, COM, ACE, FOR, "reps", "Peso corporal" ],
  [ "Sissy squat",                             LI, AIS, FUE, FOR, "reps", "Peso corporal" ],

  # ---------------- CADERA / DOMINANTE DE CADERA ----------------
  [ "Peso muerto con mancuernas",              LI, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Peso muerto con kettlebell",              LI, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Peso muerto asimétrico con mancuernas",   LI, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Peso muerto + jalón al mentón con KB",    FB, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Peso muerto + remo con barra",            FB, COM, FUE, FOR, "reps", "Barra libre" ],
  [ "Hip thrust",                              LI, COM, FUE, FOR, "reps", "Barra libre" ],
  [ "Jefferson curl con kettlebell",           LI, COM, FUE, MOV, "reps", "Kettlebell" ],
  [ "Vuelos invertidos desde peso muerto",     LS, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "KB swing",                                FB, COM, ACE, FOR, "reps", "Kettlebell" ],

  # ---------------- EMPUJE HORIZONTAL ----------------
  [ "Bench press con barra",                   LS, COM, FUE, FOR, "reps", "Barra libre" ],
  [ "Bench press con mancuernas",              LS, COM, FUE, FOR, "reps", "Mancuernas", "Sin juntar mancuernas arriba" ],
  [ "Bench press inclinado con barra",         LS, COM, FUE, FOR, "reps", "Barra libre", "Banco inclinado a 30 grados" ],
  [ "Bench press inclinado en Smith",          LS, COM, FUE, FOR, "reps", "Smith" ],
  [ "Bench press inclinado con mancuernas",    LS, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Push up",                                 LS, COM, FUE, FOR, "reps", "Peso corporal" ],
  [ "Push up sobre mancuernas",                LS, COM, FUE, FOR, "reps", "Mancuernas", "Buscando rango de movimiento" ],
  [ "Push up + remo alternado",                FB, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Fondos",                                  LS, COM, FUE, FOR, "reps", "Peso corporal" ],
  [ "Aperturas con mancuernas",                LS, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "Aperturas con power band",                LS, AIS, FUE, FOR, "reps", "Power band roja", "Brazos extendidos al frente" ],
  [ "Aperturas en máquina de cables",          LS, AIS, FUE, FOR, "reps", "Máquina de cables" ],

  # ---------------- EMPUJE VERTICAL ----------------
  [ "Press de hombro con mancuernas",          LS, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Press de hombro sentado en Smith",        LS, COM, FUE, FOR, "reps", "Smith" ],
  [ "Press de hombro con kettlebell",          LS, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Press de hombro con power band desde la jaula", LS, COM, FUE, FOR, "reps", "Power band roja" ],
  [ "Press frontal en máquina",                LS, COM, FUE, FOR, "reps", "Máquina press frontal" ],
  [ "Thrusters con mancuernas",                FB, COM, ACE, FOR, "reps", "Mancuernas" ],
  [ "Thrusters con barra",                     FB, COM, ACE, FOR, "reps", "Barra libre" ],
  [ "Thrusters con kettlebell",                FB, COM, ACE, FOR, "reps", "Kettlebell" ],
  [ "Clean and jerk",                          FB, COM, ACE, FOR, "reps", "Mancuernas" ],
  [ "Snatch con mancuerna",                    FB, COM, ACE, FOR, "reps", "Mancuernas" ],

  # ---------------- JALÓN VERTICAL ----------------
  [ "Jalón alto en máquina",                   LS, COM, FUE, FOR, "reps", "Máquina jalón alto" ],
  [ "Jalón alto con power band",               LS, COM, FUE, FOR, "reps", "Power band verde" ],
  [ "Pull up",                                 LS, COM, FUE, FOR, "reps", "Barra de dominadas" ],
  [ "Chin up",                                 LS, COM, FUE, FOR, "reps", "Barra de dominadas" ],
  [ "Progresión pull up",                      LS, COM, FUE, FOR, "reps", "TRX" ],
  [ "Pull over con kettlebell",                LS, AIS, FUE, FOR, "reps", "Kettlebell" ],
  [ "Pull over con power band",                LS, AIS, FUE, FOR, "reps", "Power band negra" ],

  # ---------------- JALÓN HORIZONTAL ----------------
  [ "Remo por brazo con mancuerna",            LS, COM, FUE, FOR, "reps", "Mancuernas", "Apoyo en step alto" ],
  [ "Remo bajo con mancuernas",                LS, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Remo bajo apoyado en banco inclinado",    LS, COM, FUE, FOR, "reps", "Banco" ],
  [ "Remo bajo con power band",                LS, COM, FUE, FOR, "reps", "Power band verde" ],
  [ "Remo en TRX",                             LS, COM, FUE, FOR, "reps", "TRX" ],
  [ "Remo en anillas",                         LS, COM, FUE, FOR, "reps", "Anillas" ],
  [ "Remo tipo gorilla con kettlebell",        LS, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Remo frontal en máquina",                 LS, COM, FUE, FOR, "reps", "Máquina remo frontal" ],
  [ "Remo alternado desde plancha",            FB, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Face pull con power band",                LS, AIS, FUE, FOR, "reps", "Power band negra" ],

  # ---------------- HOMBRO (AISLADO) ----------------
  [ "Elevaciones laterales con mancuernas",    LS, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "Elevaciones laterales con power band desde la jaula", LS, AIS, FUE, FOR, "reps", "Power band roja" ],
  [ "Elevaciones laterales acostado boca abajo", LS, AIS, FUE, FOR, "reps", "Peso corporal" ],
  [ "Elevaciones frontales acostado boca abajo", LS, AIS, FUE, FOR, "reps", "Peso corporal" ],
  [ "Abd hombro",                              LS, AIS, FUE, FOR, "reps", "Power band negra" ],
  [ "Add hombro con power band",               LS, AIS, FUE, FOR, "reps", "Power band negra" ],
  [ "Flexión de hombro con power band",        LS, AIS, FUE, MOV, "reps", "Power band roja" ],
  [ "Rotación completa de hombro con power band", LS, AIS, FUE, MOV, "reps", "Power band roja" ],
  [ "Copa con power band",                     LS, AIS, FUE, FOR, "reps", "Power band morada" ],

  # ---------------- BRAZO (AISLADO) ----------------
  [ "Curl de bíceps con mancuernas",           LS, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "Curl de bíceps tipo martillo",            LS, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "Curl de bíceps en TRX",                   LS, AIS, FUE, FOR, "reps", "TRX" ],
  [ "Curl de bíceps sentado en banco inclinado", LS, AIS, FUE, FOR, "reps", "Banco" ],
  [ "Patada de tríceps con power band",        LS, AIS, FUE, FOR, "reps", "Power band negra" ],
  [ "Extensión de codo con power band",        LS, AIS, FUE, FOR, "reps", "Power band morada" ],
  [ "Press francés con mancuernas",            LS, AIS, FUE, FOR, "reps", "Mancuernas" ],

  # ---------------- PANTORRILLA (AISLADO) ----------------
  [ "Elevaciones de talón con kettlebell",     LI, AIS, FUE, FOR, "reps", "Kettlebell" ],
  [ "Elevaciones de talón con mancuernas",     LI, AIS, FUE, FOR, "reps", "Mancuernas" ],
  [ "Elevaciones de talón en Smith",           LI, AIS, FUE, FOR, "reps", "Smith" ],
  [ "Elevación de talón sobre step bajo",      LI, AIS, FUE, FOR, "reps", "Step" ],
  [ "Elevación punta de pie con cadera apoyada", LI, AIS, FUE, FOR, "reps", "Peso corporal" ],

  # ---------------- RODILLA (MÁQUINA, AISLADO) ----------------
  [ "Extensión de rodilla en máquina",         LI, AIS, FUE, FOR, "reps", "Máquina extensión de rodilla", "Espaldar lo más atrás posible" ],
  [ "Flexión de rodilla en máquina",           LI, AIS, FUE, FOR, "reps", "Máquina flexión de rodilla" ],

  # ---------------- UNILATERAL / MARCHA ----------------
  [ "Avanzada estática con peso contrario",    LI, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Avanzadas alternadas atrás con mancuernas", LI, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Avanzadas sobre step bajo",               LI, COM, FUE, FOR, "reps", "Step" ],
  [ "Avanzada sostenida elevando talón delantero", LI, COM, FUE, FOR, "reps", "Mancuernas" ],
  [ "Step up alternado",                       LI, COM, FUE, FOR, "reps", "Step" ],
  [ "Step up con KB del lado contrario",       LI, COM, FUE, FOR, "reps", "Kettlebell" ],
  [ "Step up fortalecimiento",                 LI, COM, FUE, FOR, "reps", "Step", "Controlando el descenso" ],
  [ "Sprint jump misma pierna",                LI, COM, ACE, FOR, "reps", "Peso corporal" ],
  [ "Avanzada con salto sobre step bajo",      LI, COM, ACE, FOR, "reps", "Step" ],

  # ---------------- ZONA MEDIA ----------------
  [ "Abs con rueda",                           FB, COM, FUE, FOR, "reps", "Rueda abdominal" ],
  [ "Abs solo piernas",                        FB, AIS, FUE, FOR, "reps", "Peso corporal" ],
  [ "Abs corto con piernas elevadas",          FB, AIS, FUE, FOR, "reps", "Peso corporal" ],
  [ "Abs tipo mariposa",                       FB, AIS, FUE, FOR, "reps", "Peso corporal" ],
  [ "Abs completo con flexión y extensión de rodilla", FB, COM, FUE, FOR, "reps", "Peso corporal" ],
  [ "Plancha sostenida",                       FB, COM, FUE, FOR, "time", "Peso corporal" ],
  [ "Plancha abre y cierra",                   FB, COM, ACE, FOR, "reps", "Peso corporal" ],
  [ "Plancha con toques alternados a la cadera", FB, COM, FUE, FOR, "reps", "Peso corporal" ],
  [ "Plancha en manos cruzando pierna al frente", FB, COM, FUE, MOV, "reps", "Peso corporal" ],
  [ "Plancha sobre fitball",                   FB, COM, FUE, FOR, "reps", "Fitball" ],
  [ "Plancha lateral",                         FB, COM, FUE, FOR, "time", "Peso corporal" ],
  [ "Press pallof con power band",             FB, COM, FUE, FOR, "reps", "Power band negra" ],
  [ "Comandos alternados",                     FB, COM, ACE, FOR, "reps", "Peso corporal" ],
  [ "Superman sostenido",                      FB, COM, FUE, FOR, "time", "Peso corporal" ],
  [ "Supermán dinámico",                       FB, COM, FUE, MOV, "reps", "Peso corporal" ],

  # ---------------- CARDIO / ACELERACIÓN ----------------
  [ "Trote",                                   FB, COM, ACE, nil, "distance", "Banda (caminadora)" ],
  [ "Trote baja intensidad",                   FB, COM, ACE, nil, "time", "Banda (caminadora)" ],
  [ "Sprint",                                  FB, COM, ACE, nil, "time", "Banda (caminadora)" ],
  [ "Pique en banda",                          FB, COM, ACE, nil, "time", "Banda (caminadora)" ],
  [ "Remo en máquina",                         FB, COM, ACE, nil, "calories", "Remo (máquina)" ],
  [ "Bicicleta",                               FB, COM, ACE, nil, "calories", "Bicicleta" ],
  [ "Escaladora",                              FB, COM, ACE, nil, "time", "Escaladora" ],
  [ "Recumbent",                               FB, COM, ACE, nil, "time", "Recumbent" ],
  [ "Batidas simultáneas a la cuerda",         FB, COM, ACE, nil, "reps", "Cuerda de batida" ],
  [ "Batidas alternadas a la cuerda",          FB, COM, ACE, nil, "reps", "Cuerda de batida" ],
  [ "Burpee",                                  FB, COM, ACE, nil, "reps", "Peso corporal" ],
  [ "Semi burpee sobre step",                  FB, COM, ACE, nil, "reps", "Step" ],
  [ "Wall balls",                              FB, COM, ACE, nil, "reps", "Wall ball" ],
  [ "Jumping jacks + press",                   FB, COM, ACE, nil, "reps", "Mancuernas" ],
  [ "Skiping",                                 FB, COM, ACE, nil, "reps", "Peso corporal" ],

  # ---------------- MOVILIDAD / ACTIVACIÓN ----------------
  [ "Movilidad de cadera y lumbar tipo escorpión", FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Rotación de tronco en cuadrupedia",       FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Rotación de cadera alternada acostado",   LI, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Rotación de cadera en cuadrupedia",       LI, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Liberación posterior tipo rollito",       FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Liberación posterior sin soltar punta de los pies", FB, COM, nil, MOV, "time", "Peso corporal" ],
  [ "Liberación posterior sentado con piernas abiertas", FB, COM, nil, MOV, "time", "Peso corporal" ],
  [ "Liberación posterior desde cuadrupedia",  FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Liberación lumbar lleva pierna al lado",  FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Liberación escapular",                    LS, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Liberación flexor de cadera sobre step",  LI, COM, nil, MOV, "time", "Step" ],
  [ "Coordinación lumbo pélvica \"gato\"",     FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Colgado en barra",                        LS, COM, nil, MOV, "time", "Barra de dominadas" ],
  [ "Monstruos",                               FB, COM, ACE, MOV, "reps", "Peso corporal" ],
  [ "Plancha en manos + apertura de cadera",   FB, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Activación de cuádriceps desde cuadrupedia", LI, AIS, nil, MOV, "reps", "Power band negra" ],
  [ "Activación pectoral y hombro desde cuadrupedia", LS, AIS, nil, MOV, "reps", "Peso corporal" ],
  [ "Apertura de cadera en posición de rodilla", LI, COM, nil, MOV, "reps", "Peso corporal" ],
  [ "Rotación con KB en posición de avanzada", FB, COM, nil, MOV, "reps", "Kettlebell" ]
].freeze

created = updated = 0
EXERCISES.each do |name, region, structure, quality, purpose, measure, equipment, cue|
  ex = Exercise.find_or_initialize_by(name_es: name)
  ex.new_record? ? created += 1 : updated += 1
  ex.assign_attributes(
    muscle_region: region,
    movement_structure: structure,
    training_quality: quality,
    training_purpose: purpose,
    default_measure_kind: measure,
    default_equipment_item: EquipmentItem.find_by(name_es: equipment),
    technique_notes: cue,
    taxonomy_confirmed: false
  )
  ex.save!
end

puts "  exercises: #{Exercise.count} (#{created} new, #{updated} updated)"
puts "    tren inferior #{Exercise.region_tren_inferior.count} · " \
     "tren superior #{Exercise.region_tren_superior.count} · " \
     "full body #{Exercise.region_full_body.count}"
puts "    compuesto #{Exercise.movement_structure_compuesto.count} · " \
     "aislado #{Exercise.movement_structure_aislado.count}"
puts "    awaiting Cristian's confirmation: #{Exercise.unconfirmed.count}"
