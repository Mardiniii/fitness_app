class CreateExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :exercises do |t|
      # Names are long and descriptive in the source documents:
      # "Liberacion posterior sin soltar punta de pies"
      t.string :name_es, null: false
      t.string :name_en
      t.string :slug, null: false

      # Lowercased + accent-stripped by the model (I18n.transliterate).
      # Kept as a real column so the trigram index needs no custom SQL
      # function -- which keeps schema.rb usable instead of structure.sql.
      t.string :search_name, null: false, default: ""

      t.string :muscle_group
      t.string :secondary_muscles, array: true, default: []
      t.string :movement_pattern      # squat, hinge, push, pull, carry, gait

      t.enum :default_measure_kind, enum_type: "measure_kind", null: false, default: "reps"
      t.references :default_equipment_item, foreign_key: { to_table: :equipment_items }

      t.text   :technique_notes
      t.string :reference_url         # cheap stand-in for video upload

      # null practitioner_id = global library entry
      t.references :practitioner, foreign_key: { to_table: :users }

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :exercises, :slug, unique: true
    add_index :exercises, :muscle_group
    add_index :exercises, :search_name
    # Fuzzy matching on plan import: names vary between weeks and accents
    # are inconsistent ("Liberacion" / "Liberacion")
    add_index :exercises, :search_name, using: :gin, opclass: :gin_trgm_ops,
              name: "idx_exercises_search_name_trgm"
  end
end
