FactoryBot.define do
  factory :program do
    association :practitioner, factory: :practitioner
    name { "Hipertrofia / Pérdida de grasa" }
    goal { "Ganar masa muscular" }
  end

  factory :program_version do
    program
    status { "draft" }
  end

  factory :program_week do
    program_version
    sequence(:position) { |n| n }
  end

  factory :program_day do
    program_week
    sequence(:position) { |n| n }
    focus { "PIERNA (ENFOQUE CUÁDRICEPS)" }
  end

  factory :program_block do
    program_day
    sequence(:position) { |n| n }
    name { "Bloque 1" }
    execution_mode { "straight_sets" }
    round_count { 3 }
  end

  factory :block_exercise do
    program_block
    exercise
    sequence(:position) { |n| n }
  end

  factory :prescribed_set do
    block_exercise
    set_number { 1 }
    segment_number { 1 }
    measure_kind { "reps" }
    reps_min { 12 }
    load_kind { "external" }
    load_value { 20 }
    load_unit { "lb" }
  end

  factory :program_assignment do
    program_version
    association :client, factory: :client
    practitioner { program_version.program.practitioner }
    starts_on { Date.current }
  end
end

FactoryBot.define do
  factory :block_exercise_alternative_record, class: "BlockExerciseAlternative" do
    block_exercise
    exercise
    position { 1 }
  end
end
