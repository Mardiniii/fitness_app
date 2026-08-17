class CreateCheckIns < ActiveRecord::Migration[8.0]
  def change
    # A direct port of the log table at the back of Cristian's 2026 plan.
    # Four fields, unchanged, because he already validated them in practice.
    create_table :check_ins do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :program_assignment, foreign_key: true

      t.date    :week_of, null: false
      t.decimal :bodyweight_kg,   precision: 5, scale: 2
      t.integer :feeling                                   # "Sensacion General (1-10)"
      t.decimal :sleep_hours_avg, precision: 3, scale: 1
      t.text    :notes                                     # "Notas del Progreso"
      t.timestamps
    end

    add_index :check_ins, %i[client_id week_of], unique: true
    add_check_constraint :check_ins,
                         "feeling IS NULL OR (feeling >= 1 AND feeling <= 10)",
                         name: "chk_feeling_range"
  end
end
