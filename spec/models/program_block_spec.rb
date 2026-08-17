require "rails_helper"

RSpec.describe ProgramBlock do
  describe "execution_mode" do
    # Regression: migration 20260817180200 added 'biseries' to the Postgres
    # enum and to both locale files, but the model's pg_enum list still
    # stopped at four values. Any block stored as 'biseries' -- and ten of
    # Cristian's plans use them -- raised on read.
    it "round-trips every value the database enum allows" do
      db_values = ActiveRecord::Base.connection
                                    .select_values("SELECT unnest(enum_range(NULL::execution_mode))")

      expect(db_values).to match_array(described_class.execution_modes.values)

      db_values.each do |mode|
        block = create(:program_block, execution_mode: mode)
        expect(block.reload.execution_mode).to eq(mode)
      end
    end

    it "rejects a value the database does not know" do
      block = build(:program_block, execution_mode: "superserie")
      expect(block).not_to be_valid
    end
  end

  describe "#copy_into!" do
    it "carries nested blocks, prescribed sets and stated alternatives across" do
      day    = create(:program_day)
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      child  = create(:program_block, program_day: day, parent_block: parent)
      be     = create(:block_exercise, program_block: child, per_side: true,
                                       technique_notes: "Controla la bajada")
      create(:prescribed_set, block_exercise: be, set_number: 1, reps_min: 10)
      create(:prescribed_set, block_exercise: be, set_number: 1, segment_number: 2, reps_min: 8)
      alternative = create(:exercise)
      create(:block_exercise_alternative_record, block_exercise: be, exercise: alternative)

      target = create(:program_day)
      copy   = parent.copy_into!(day: target)

      expect(copy.child_blocks.count).to eq(1)
      copied_be = copy.child_blocks.first.block_exercises.first
      expect(copied_be.per_side).to be(true)
      expect(copied_be.technique_notes).to eq("Controla la bajada")
      expect(copied_be.prescribed_sets.count).to eq(2)
      expect(copied_be.prescribed_sets.map(&:segment_number)).to eq([ 1, 2 ])
      expect(copied_be.alternative_exercises).to eq([ alternative ])
    end
  end

  describe "nesting" do
    it "refuses to be its own parent" do
      block = create(:program_block)
      block.parent_block_id = block.id
      expect(block).not_to be_valid
    end
  end
end
