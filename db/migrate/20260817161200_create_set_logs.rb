class CreateSetLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :set_logs do |t|
      t.references :session,        null: false, foreign_key: true
      t.references :block_exercise, null: false, foreign_key: true

      # What was ACTUALLY performed. Differs from the prescribed exercise when
      # the client substitutes. Without this, a substituted session silently
      # corrupts the progression chart for two exercises at once.
      t.references :exercise, null: false, foreign_key: true

      t.integer :set_number,     null: false
      t.integer :segment_number, null: false, default: 1

      t.integer :reps_completed
      t.decimal :load_value, precision: 7, scale: 2
      t.enum    :load_unit, enum_type: "load_unit"
      t.integer :duration_seconds
      t.decimal :distance_value, precision: 9, scale: 2   # metres
      t.integer :calories
      t.decimal :rpe_reported, precision: 3, scale: 1

      t.datetime :completed_at
      t.boolean  :skipped, null: false, default: false
      t.text     :notes

      # Generated on the phone. Makes offline sync idempotent -- a set logged
      # in a basement syncs exactly once however many times the queue retries.
      t.uuid :client_uuid, null: false, default: -> { "gen_random_uuid()" }
      t.timestamps
    end

    add_index :set_logs, :client_uuid, unique: true
    add_index :set_logs, %i[session_id block_exercise_id set_number segment_number],
              unique: true, name: "idx_set_logs_unique"

    # Powers the "last time" panel on the set-logging screen -- the single most
    # valuable element on the most important screen in the product
    add_index :set_logs, %i[exercise_id completed_at], order: { completed_at: :desc }
  end
end
