class CreatePrograms < ActiveRecord::Migration[8.0]
  def change
    # Identity only. All content lives in versions.
    create_table :programs do |t|
      t.references :practitioner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false     # "Hipertrofia / Perdida de grasa"
      t.string :goal
      t.text   :description
      t.datetime :discarded_at
      t.timestamps
    end

    # Versioning answers "what happens when a practitioner edits a program a
    # client is mid-way through?" -- an assignment pins a version, so it can't.
    create_table :program_versions do |t|
      t.references :program, null: false, foreign_key: true
      t.integer  :version_number, null: false, default: 1
      t.enum     :status, enum_type: "program_version_status", null: false, default: "draft"
      t.integer  :duration_weeks
      t.datetime :published_at
      # FK added in 20260817161500 -- programs and plan_imports reference each
      # other, so one side has to come after both tables exist.
      t.bigint   :source_import_id
      t.timestamps
    end

    add_index :program_versions, %i[program_id version_number], unique: true
    add_index :program_versions, :source_import_id
  end
end
