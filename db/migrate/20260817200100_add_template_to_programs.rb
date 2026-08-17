# Cristian needs structure reused and prescription tailored: the same
# "Hipertrofia base" adapted per client, because loads are personal
# ("bench press 25lb" is Sebastian's number, not everyone's).
#
# Assigning a template deep-copies it into a client-specific program, so a
# correction to one client's plan never leaks into another's, and the version
# an assignment pins stays frozen.
class AddTemplateToPrograms < ActiveRecord::Migration[8.0]
  def change
    add_column :programs, :template, :boolean, null: false, default: false
    add_reference :programs, :source_program, foreign_key: { to_table: :programs }
    add_index :programs, %i[practitioner_id template]
  end
end
