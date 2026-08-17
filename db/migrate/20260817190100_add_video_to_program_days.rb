# Cristian records a walkthrough of the whole session, not only per-movement
# demos. The exercise-level video (Exercise#reference_url) covers "how do I do
# this movement"; this covers "here is today's workout and why".
class AddVideoToProgramDays < ActiveRecord::Migration[8.0]
  def change
    add_column :program_days, :reference_url, :string
  end
end
