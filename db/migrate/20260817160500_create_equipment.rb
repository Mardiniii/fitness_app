class CreateEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_items do |t|
      t.string :name_es, null: false        # "Power band verde"
      t.string :name_en
      t.enum   :kind, enum_type: "equipment_kind", null: false

      # Band colour IS the load. Structured, never free text, or progression
      # tracking on band work becomes impossible.
      t.string  :resistance_label           # "verde", "morada", "dorado"
      t.decimal :default_load_value, precision: 7, scale: 2
      t.enum    :default_load_unit, enum_type: "load_unit"
      t.timestamps
    end

    add_index :equipment_items, :name_es, unique: true

    # A plan referencing equipment the client does not own is not executable
    create_table :client_equipment do |t|
      t.references :client_profile, null: false, foreign_key: true
      t.references :equipment_item, null: false, foreign_key: true
      t.text :notes
      t.timestamps
    end

    add_index :client_equipment, %i[client_profile_id equipment_item_id],
              unique: true, name: "idx_client_equipment_unique"
  end
end
