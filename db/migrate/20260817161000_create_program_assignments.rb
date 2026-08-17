class CreateProgramAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :program_assignments do |t|
      # Pins a VERSION, not a program -- later edits cannot disturb this client
      t.references :program_version, null: false, foreign_key: true
      t.references :client,          null: false, foreign_key: { to_table: :users }
      t.references :practitioner,    null: false, foreign_key: { to_table: :users }
      t.date :starts_on, null: false
      t.date :ends_on
      t.enum :status, enum_type: "assignment_status", null: false, default: "active"
      t.text :notes
      t.timestamps
    end

    add_index :program_assignments, %i[client_id status]
  end
end
