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
