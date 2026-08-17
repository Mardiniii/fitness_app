class AddSourceImportFk < ActiveRecord::Migration[8.0]
  # Closes the circular reference between program_versions and plan_imports:
  # an import produces a version, and a version records which import made it.
  def change
    add_foreign_key :program_versions, :plan_imports, column: :source_import_id
  end
end
