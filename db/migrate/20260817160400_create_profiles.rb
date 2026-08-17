class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :practitioner_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.enum   :specialty, enum_type: "practitioner_specialty", null: false, default: "trainer"
      t.text   :bio
      t.string :phone
      t.timestamps
    end

    create_table :client_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      # birth_year, not date_of_birth -- age is all the product needs
      t.integer :birth_year
      t.decimal :height_cm, precision: 5, scale: 1
      t.string  :sex
      t.string  :goal        # "Hipertrofia / Perdida de grasa"
      t.text    :notes
      t.timestamps
    end

    create_table :practitioner_clients do |t|
      t.references :practitioner, null: false, foreign_key: { to_table: :users }
      t.references :client,       null: false, foreign_key: { to_table: :users }
      t.enum :relationship_type, enum_type: "relationship_type",   null: false, default: "trainer"
      t.enum :status,            enum_type: "relationship_status", null: false, default: "invited"
      t.datetime :invited_at
      t.datetime :accepted_at
      t.datetime :ended_at
      t.timestamps
    end

    # A client may have a trainer AND a nutritionist. This plain join is what
    # makes cross-practitioner visibility a query later rather than a rewrite.
    add_index :practitioner_clients, %i[practitioner_id client_id relationship_type],
              unique: true, name: "idx_practitioner_clients_unique"

    create_table :client_injuries do |t|
      t.references :client_profile, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :notes
      t.boolean :active, null: false, default: true
      t.date    :reported_at
      t.timestamps
    end
  end
end
