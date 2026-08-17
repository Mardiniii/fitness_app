class CreatePlanImports < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_imports do |t|
      t.references :practitioner, null: false, foreign_key: { to_table: :users }
      t.enum :source_type, enum_type: "import_source_type", null: false, default: "paste"

      # Kept permanently: the regression corpus for the parser, and the audit
      # trail when a program looks wrong six months from now.
      t.text  :source_text
      t.jsonb :parsed_payload,   null: false, default: {}
      t.jsonb :confidence_flags, null: false, default: {}

      t.enum :status, enum_type: "import_status", null: false, default: "pending"
      t.text :error_message
      t.references :program_version, foreign_key: true    # set on commit
      t.timestamps
    end

    add_index :plan_imports, %i[practitioner_id status]
  end
end
