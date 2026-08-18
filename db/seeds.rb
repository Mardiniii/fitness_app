# Seeds reset the database to a known state, every time.
#
# "Idempotent" was the old goal and it was the wrong one: find_or_create left
# half-migrated rows from earlier runs lying around, so a bug could hide behind
# data that no fresh install would ever produce. Wiping first means what you
# see locally is exactly what a new machine gets.
#
# V1 is deliberately a single practitioner/client dyad -- Cristian coaching
# Sebastian -- because a working loop for one real pair is what proves the
# product before any multi-tenant machinery gets built.

DEFAULT_PASSWORD = ENV.fetch("SEED_PASSWORD", "fitfusion123")

# --- wipe -------------------------------------------------------------------
# TRUNCATE ... RESTART IDENTITY CASCADE rather than destroy_all: it ignores
# association order, resets sequences so ids start at 1 again, and cannot be
# defeated by a dependent: :restrict_with_error.
def wipe_all_tables!
  connection = ActiveRecord::Base.connection
  protected_tables = %w[schema_migrations ar_internal_metadata]
  tables = connection.tables - protected_tables
  return if tables.empty?

  quoted = tables.map { |t| connection.quote_table_name(t) }.join(", ")
  connection.execute("TRUNCATE #{quoted} RESTART IDENTITY CASCADE")
  tables
end

# The guard is deliberate. On Heroku this database holds sessions a real person
# actually logged, and there is no undo. Destroying it has to be a sentence
# somebody typed on purpose.
if Rails.env.production? && ENV["SEED_DESTRUCTIVE"] != "true"
  abort <<~MSG
    Refusing to seed production without SEED_DESTRUCTIVE=true.

    These seeds wipe every table first. In production that deletes real logged
    sessions permanently. If that is genuinely what you want:

        heroku run "SEED_DESTRUCTIVE=true rails db:seed"
  MSG
end

wiped = wipe_all_tables!
puts "Wiped #{wiped.size} tables and reset their id sequences."

# --- reference data ---------------------------------------------------------
load Rails.root.join("db/seeds/equipment.rb")
load Rails.root.join("db/seeds/exercises.rb")

# --- people -----------------------------------------------------------------
practitioner = User.create!(
  email: ENV.fetch("SEED_TRAINER_EMAIL", "cristian@fitfusion.local"),
  name: "Cristian Franco",
  role: "practitioner",
  locale: "es",
  timezone: "America/Bogota",
  unit_preference: "metric",
  password: DEFAULT_PASSWORD
)
PractitionerProfile.create!(user: practitioner, specialty: "trainer")

# Three clients, deliberately at different stages, because a roster where
# everyone looks identical proves nothing about the screen that is supposed to
# tell Cristian who needs attention.
CLIENTS = [
  { email_env: "SEED_CLIENT_EMAIL", email: "sebastian@fitfusion.local",
    name: "Sebastian Zapata", goal: "Hipertrofia / Pérdida de grasa",
    timezone: "America/New_York", injuries: [], equipment: [ "Mancuernas", "Kettlebell" ] },

  { email_env: "SEED_CLIENT2_EMAIL", email: "estefania@fitfusion.local",
    name: "Estefania Zapata Mardini", goal: "Fuerza base y movilidad",
    timezone: "America/Bogota",
    injuries: [ "Molestia en hombro derecho" ],
    equipment: [ "Mancuernas", "Power band verde" ] },

  { email_env: "SEED_CLIENT3_EMAIL", email: "katherine@fitfusion.local",
    name: "Katherine Hincapie Osorio", goal: "Volver a entrenar con constancia",
    timezone: "America/Bogota", injuries: [],
    equipment: [ "Power band roja" ] }
].freeze

clients = CLIENTS.map do |spec|
  user = User.create!(
    email: ENV.fetch(spec[:email_env], spec[:email]),
    name: spec[:name],
    role: "client",
    locale: "es",
    timezone: spec[:timezone],
    unit_preference: "metric",
    password: DEFAULT_PASSWORD
  )
  profile = ClientProfile.create!(user: user, goal: spec[:goal])

  spec[:injuries].each do |name|
    ClientInjury.create!(client_profile: profile, name: name, active: true,
                         reported_at: 3.months.ago.to_date)
  end

  spec[:equipment].each do |name|
    item = EquipmentItem.find_by(name_es: name)
    ClientEquipment.create!(client_profile: profile, equipment_item: item) if item
  end

  PractitionerClient.create!(
    practitioner: practitioner, client: user,
    relationship_type: "trainer", status: "active", accepted_at: Time.current
  )

  user
end

client = clients.first

puts "Seeded #{User.count} users."
puts "  practitioner: #{practitioner.email}"
clients.each { |c| puts "  client:       #{c.email}  (#{c.name})" }
puts "  password:     #{DEFAULT_PASSWORD}"

# SEMANA 1 of the real plan. Not fixture data -- it is the week Sebastian is
# actually training -- so it is worth having in production too, where it gives
# the deployed app something to walk end to end. Opt-in there, on by default
# everywhere else.
if ENV.fetch("SEED_SAMPLE_PROGRAM", Rails.env.production? ? "false" : "true") == "true"
  load Rails.root.join("db/seeds/sample_program.rb")
  load Rails.root.join("db/seeds/history.rb")
else
  puts "  sample program skipped (set SEED_SAMPLE_PROGRAM=true to include it)"
end
