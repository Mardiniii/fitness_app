class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :program_assignment, null: false, foreign_key: true
      t.references :program_day,        null: false, foreign_key: true

      # Nullable: days are "Dia 1..4", not weekday-anchored. Day N unlocks
      # when N-1 completes, so the client self-schedules.
      t.date     :scheduled_for
      t.datetime :started_at
      t.datetime :completed_at
      t.enum     :status, enum_type: "session_status", null: false, default: "pending"

      t.decimal :overall_rpe, precision: 3, scale: 1
      t.integer :duration_seconds
      t.text    :notes
      t.timestamps
    end

    add_index :sessions, %i[program_assignment_id scheduled_for]
    add_index :sessions, %i[program_assignment_id status]
  end
end
