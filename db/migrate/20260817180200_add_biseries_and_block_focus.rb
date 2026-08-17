class AddBiseriesAndBlockFocus < ActiveRecord::Migration[8.0]
  # ALTER TYPE ... ADD VALUE is transaction-safe on PG 12+, but disabling the
  # DDL transaction keeps this migration portable if the DB is ever older.
  disable_ddl_transaction!

  def up
    # "Parte principal: trabajo en biseries" appears in 10 of the plans. A
    # biserie is two exercises back to back -- distinct from `circuit` (3+) and
    # from `paired` (two whole blocks alternating), and he names it explicitly.
    execute "ALTER TYPE execution_mode ADD VALUE IF NOT EXISTS 'biseries'"

    # "Bloque 1 tren superior", "Bloque 3 zona media + cardio" -- blocks carry
    # their own focus label, not just days.
    add_column :program_blocks, :focus, :string
  end

  def down
    remove_column :program_blocks, :focus
    # PostgreSQL cannot remove a value from an enum; leaving 'biseries' in place
    # is harmless and the only safe direction.
  end
end
