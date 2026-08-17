FactoryBot.define do
  factory :equipment_item do
    sequence(:name_es) { |n| "Mancuernas #{n}" }
    kind { "dumbbell" }
  end

  factory :exercise do
    sequence(:name_es) { |n| "Sentadilla #{n}" }
    muscle_region { "tren_inferior" }
    movement_structure { "compuesto" }
    training_quality { "fuerza" }
    training_purpose { "fortaleza" }
    default_measure_kind { "reps" }
    taxonomy_confirmed { false }
  end
end
