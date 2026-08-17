# Equipment vocabulary, taken from what the plans actually reference.
# Band colour is a resistance specification, so each band is its own item.
EQUIPMENT = [
  # kind, name_es, resistance_label
  [ "band",       "Power band roja",    "roja" ],
  [ "band",       "Power band morada",  "morada" ],
  [ "band",       "Power band verde",   "verde" ],
  [ "band",       "Power band negra",   "negra" ],
  [ "band",       "Elástico dorado",    "dorado" ],
  [ "dumbbell",   "Mancuernas",         nil ],
  [ "kettlebell", "Kettlebell",         nil ],
  [ "barbell",    "Barra libre",        nil ],
  [ "machine",    "Smith",              nil ],
  [ "machine",    "Máquina de cables",  nil ],
  [ "machine",    "Máquina jalón alto", nil ],
  [ "machine",    "Máquina remo frontal", nil ],
  [ "machine",    "Máquina extensión de rodilla", nil ],
  [ "machine",    "Máquina flexión de rodilla", nil ],
  [ "machine",    "Máquina press frontal", nil ],
  [ "accessory",  "TRX",                nil ],
  [ "accessory",  "Anillas",            nil ],
  [ "accessory",  "Step",               nil ],
  [ "accessory",  "Jaula",              nil ],
  [ "accessory",  "Banco",              nil ],
  [ "accessory",  "Fitball",            nil ],
  [ "accessory",  "Rueda abdominal",    nil ],
  [ "accessory",  "Cuerda de batida",   nil ],
  [ "accessory",  "Wall ball",          nil ],
  [ "accessory",  "Barra de dominadas", nil ],
  [ "cardio",     "Banda (caminadora)", nil ],
  [ "cardio",     "Remo (máquina)",     nil ],
  [ "cardio",     "Bicicleta",          nil ],
  [ "cardio",     "Escaladora",         nil ],
  [ "cardio",     "Recumbent",          nil ],
  [ "bodyweight", "Peso corporal",      nil ]
].freeze

EQUIPMENT.each do |kind, name_es, resistance|
  item = EquipmentItem.find_or_initialize_by(name_es: name_es)
  item.kind = kind
  item.resistance_label = resistance
  item.save!
end

puts "  equipment: #{EquipmentItem.count}"
