class CreateProgramStructure < ActiveRecord::Migration[8.0]
  def change
    create_table :program_weeks do |t|
      t.references :program_version, null: false, foreign_key: true
      t.integer :position, null: false   # 1..4
      t.string  :name                    # "SEMANA 1"
      t.string  :focus
      t.timestamps
    end
    add_index :program_weeks, %i[program_version_id position], unique: true

    create_table :program_days do |t|
      t.references :program_week, null: false, foreign_key: true
      t.integer :position, null: false   # "Dia 1".."Dia 4"
      t.string  :name
      t.string  :focus                   # "PIERNA (ENFOQUE CUADRICEPS)"
      t.text    :description
      t.timestamps
    end
    add_index :program_days, %i[program_week_id position], unique: true

    create_table :program_blocks do |t|
      t.references :program_day, null: false, foreign_key: true
      # Self-reference carries "1 serie = realizar bloque A + bloque B"
      t.references :parent_block, foreign_key: { to_table: :program_blocks }

      t.integer :position, null: false
      t.string  :name                    # "Calentamiento", "Bloque 1"
      t.enum    :execution_mode, enum_type: "execution_mode",
                null: false, default: "straight_sets"
      t.integer :round_count             # "3 series", "8 series"

      # Interval blocks: 30"x10" -> work 30, rest 10. A bare "Descanso" bullet
      # in the source is stored here, never as an exercise row.
      t.integer :work_seconds
      t.integer :rest_seconds
      t.integer :rest_between_rounds_seconds

      t.text :notes
      t.timestamps
    end
    add_index :program_blocks, %i[program_day_id position]

    create_table :block_exercises do |t|
      t.references :program_block, null: false, foreign_key: true
      t.references :exercise,      null: false, foreign_key: true
      t.integer :position, null: false
      # "15 remo por brazo" -- reps are per side, volume doubles
      t.boolean :per_side, null: false, default: false
      # The coaching: "Controla la bajada", "Banco inclinado a 30 grados".
      # Rendered on the set-logging screen, not buried in a detail view.
      t.text    :technique_notes
      t.timestamps
    end
    add_index :block_exercises, %i[program_block_id position]

    # "15 remo en trx o progresion de pull up en Smith o barra"
    # One slot, several acceptable movements.
    create_table :block_exercise_alternatives do |t|
      t.references :block_exercise, null: false, foreign_key: true
      t.references :exercise,       null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string  :note                    # "o mancuernas 25lb"
      t.timestamps
    end
    add_index :block_exercise_alternatives, %i[block_exercise_id exercise_id],
              unique: true, name: "idx_block_exercise_alts_unique"
  end
end
