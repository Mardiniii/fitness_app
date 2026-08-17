# Idempotent. Safe to re-run.
#
# V1 is deliberately a single practitioner/client dyad -- Cristian coaching
# Sebastian -- because a working loop for one real pair is what proves the
# product before any of the multi-tenant machinery gets built.

DEFAULT_PASSWORD = ENV.fetch("SEED_PASSWORD", "fitfusion123")

practitioner = User.find_or_initialize_by(email: ENV.fetch("SEED_TRAINER_EMAIL", "cristian@fitfusion.local"))
practitioner.assign_attributes(
  name: "Cristian Franco",
  role: "practitioner",
  locale: "es",
  timezone: "America/Bogota",
  unit_preference: "metric"
)
practitioner.password = DEFAULT_PASSWORD if practitioner.new_record?
practitioner.save!
PractitionerProfile.find_or_create_by!(user: practitioner) { |p| p.specialty = "trainer" }

client = User.find_or_initialize_by(email: ENV.fetch("SEED_CLIENT_EMAIL", "sebastian@fitfusion.local"))
client.assign_attributes(
  name: "Sebastian Zapata",
  role: "client",
  locale: "es",
  timezone: "America/New_York",
  unit_preference: "metric"
)
client.password = DEFAULT_PASSWORD if client.new_record?
client.save!
ClientProfile.find_or_create_by!(user: client) do |p|
  p.goal = "Hipertrofia / Pérdida de grasa"
end

PractitionerClient.find_or_create_by!(
  practitioner: practitioner, client: client, relationship_type: "trainer"
) do |rel|
  rel.status = "active"
  rel.accepted_at = Time.current
end

puts "Seeded #{User.count} users."
puts "  practitioner: #{practitioner.email}"
puts "  client:       #{client.email}"
puts "  password:     #{DEFAULT_PASSWORD}"
