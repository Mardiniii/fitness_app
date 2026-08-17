# Cristian classifies movements along four axes of his own. They are not the
# generic "muscle group / movement pattern" taxonomy I originally guessed at,
# so the guess comes out and his axes go in. Values stay in Spanish because
# they are his working vocabulary -- "Aceleración" vs "Fuerza" is a
# methodological distinction, not a word to translate.
class AddPractitionerTaxonomyToExercises < ActiveRecord::Migration[8.0]
  def up
    create_enum :muscle_region,      %w[tren_inferior tren_superior full_body]
    create_enum :movement_structure, %w[aislado compuesto]
    create_enum :training_quality,   %w[aceleracion fuerza]
    create_enum :training_purpose,   %w[movilidad fortaleza]

    add_column :exercises, :muscle_region,      :enum, enum_type: "muscle_region"
    add_column :exercises, :movement_structure, :enum, enum_type: "movement_structure"
    add_column :exercises, :training_quality,   :enum, enum_type: "training_quality"
    add_column :exercises, :training_purpose,   :enum, enum_type: "training_purpose"

    # Seeded rows are classified by us from the plan PDFs; only rows Cristian
    # has actually reviewed get flipped to true. Gives him a review queue
    # instead of silently presenting our guesses as his taxonomy.
    add_column :exercises, :taxonomy_confirmed, :boolean, null: false, default: false

    add_index :exercises, :muscle_region
    add_index :exercises, %i[muscle_region movement_structure]

    # Invented, unused, and superseded by the axes above
    remove_column :exercises, :movement_pattern
    remove_column :exercises, :secondary_muscles
  end

  def down
    remove_column :exercises, :muscle_region
    remove_column :exercises, :movement_structure
    remove_column :exercises, :training_quality
    remove_column :exercises, :training_purpose
    remove_column :exercises, :taxonomy_confirmed
    add_column :exercises, :movement_pattern, :string
    add_column :exercises, :secondary_muscles, :string, array: true, default: []
    %i[muscle_region movement_structure training_quality training_purpose].each { |e| drop_enum e }
  end
end
