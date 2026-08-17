class CreatePrescribedSets < ActiveRecord::Migration[8.0]
  def change
    # One row per set. Sets are NOT homogeneous:
    #   "15-12-10 Bench press barra 15/20/25lb"   (SEMANA 4, Dia 1)
    # is three distinct rows. segment_number > 1 carries drop sets:
    #   "10 extension de rodilla en maquina 100lb + 10 con 70lb"
    create_table :prescribed_sets do |t|
      t.references :block_exercise, null: false, foreign_key: true
      t.integer :set_number,     null: false
      t.integer :segment_number, null: false, default: 1

      t.enum :measure_kind, enum_type: "measure_kind", null: false, default: "reps"

      t.integer :reps_min                                  # 12, or 10 for "10-12"
      t.integer :reps_max                                  # nil, or 12 for "10-12"
      t.integer :work_seconds                              # "3min de remo" -> 180
      t.decimal :distance_value, precision: 9, scale: 2    # canonical METRES
      t.enum    :distance_unit, enum_type: "distance_unit" # display preference
      t.integer :calories                                  # "12 row cal"

      t.enum    :load_kind, enum_type: "load_kind", null: false, default: "none"
      t.decimal :load_value,     precision: 7, scale: 2
      t.decimal :load_value_max, precision: 7, scale: 2    # "20/25lb" -> 20, 25
      t.enum    :load_unit, enum_type: "load_unit"
      t.references :equipment_item, foreign_key: true      # band colour, machine
      t.string  :load_note

      t.decimal :target_rpe, precision: 3, scale: 1        # 8.5 -- half points are real
      t.integer :rest_seconds                              # normalised from "8 seg" / "2 min"
      t.text    :notes
      t.timestamps
    end

    add_index :prescribed_sets, %i[block_exercise_id set_number segment_number],
              unique: true, name: "idx_prescribed_sets_unique"

    # Fail loudly if the import parser produces something incoherent
    add_check_constraint :prescribed_sets, <<~SQL.squish, name: "chk_measure_kind_columns"
      (measure_kind = 'reps'     AND reps_min       IS NOT NULL) OR
      (measure_kind = 'time'     AND work_seconds   IS NOT NULL) OR
      (measure_kind = 'distance' AND distance_value IS NOT NULL) OR
      (measure_kind = 'calories' AND calories       IS NOT NULL)
    SQL

    add_check_constraint :prescribed_sets,
                         "reps_max IS NULL OR reps_min IS NULL OR reps_max >= reps_min",
                         name: "chk_rep_range_ordered"

    add_check_constraint :prescribed_sets,
                         "target_rpe IS NULL OR (target_rpe >= 1 AND target_rpe <= 10)",
                         name: "chk_rpe_range"
  end
end
