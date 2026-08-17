class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.citext :email,              null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :name,               null: false
      t.enum   :role, enum_type: "user_role", null: false, default: "client"

      # i18n from the first migration -- Cristian and Andres work in Spanish
      t.string :locale,   null: false, default: "es"
      t.string :timezone, null: false, default: "America/Bogota"
      t.enum   :unit_preference, enum_type: "unit_system", null: false, default: "metric"

      # Devise (database_authenticatable, recoverable, rememberable)
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.datetime :confirmed_at

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
  end
end
