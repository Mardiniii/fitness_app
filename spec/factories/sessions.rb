FactoryBot.define do
  factory :session do
    program_assignment
    program_day
    status { "pending" }
  end

  factory :set_log do
    session
    block_exercise
    exercise { block_exercise.exercise }
    set_number { 1 }
    segment_number { 1 }
    reps_completed { 12 }
    load_value { 20 }
    load_unit { "lb" }
    completed_at { Time.current }
  end
end

FactoryBot.define do
  factory :check_in do
    association :client, factory: :client
    week_of { Date.current.beginning_of_week }
    bodyweight_kg { 78.0 }
    feeling { 7 }
    sleep_hours_avg { 7.0 }
  end
end

FactoryBot.define do
  factory :client_injury_record, class: "ClientInjury" do
    client_profile
    name { "Molestia en hombro derecho" }
    active { true }
  end

  factory :client_equipment_record, class: "ClientEquipment" do
    client_profile
    equipment_item
  end
end
