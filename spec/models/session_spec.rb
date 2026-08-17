require "rails_helper"

RSpec.describe Session do
  let(:assignment) { create(:program_assignment) }
  let(:day)        { create(:program_day, program_week: create(:program_week, program_version: assignment.program_version)) }
  let(:session)    { create(:session, program_assignment: assignment, program_day: day) }

  describe "#start!" do
    it "moves a pending session to in_progress and stamps started_at" do
      expect { session.start! }
        .to change { session.status }.from("pending").to("in_progress")
      expect(session.started_at).to be_present
    end

    it "is idempotent -- reopening a session mid-workout does not reset the clock" do
      session.start!
      first = session.started_at

      travel_to(1.hour.from_now) { session.start! }

      expect(session.reload.started_at.to_i).to eq(first.to_i)
      expect(session.status).to eq("in_progress")
    end
  end

  describe "#complete!" do
    it "records duration from the moment the session actually started" do
      session.start!
      travel_to(45.minutes.from_now) { session.complete! }

      expect(session.reload.status).to eq("completed")
      expect(session.duration_seconds).to be_within(2).of(45 * 60)
    end

    it "survives a session that was never explicitly started" do
      expect { session.complete! }.not_to raise_error
      expect(session.duration_seconds).to be_nil
    end
  end

  describe "#prescribed_set_count" do
    # Regression: this used program_day.program_blocks, which is scoped to
    # top-level blocks. A day with a nested "bloque A + bloque B" reported a
    # total that excluded the nested sets, so progress could exceed 100%.
    it "counts sets inside nested blocks, not just top-level ones" do
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      child  = create(:program_block, program_day: day, parent_block: parent)

      top_be    = create(:block_exercise, program_block: parent)
      nested_be = create(:block_exercise, program_block: child)
      create(:prescribed_set, block_exercise: top_be,    set_number: 1)
      create(:prescribed_set, block_exercise: nested_be, set_number: 1)
      create(:prescribed_set, block_exercise: nested_be, set_number: 2)

      expect(session.prescribed_set_count).to eq(3)
    end

    it "is zero for a day with no blocks" do
      expect(session.prescribed_set_count).to eq(0)
    end
  end

  describe "#progress" do
    it "does not divide by zero when nothing is prescribed" do
      expect(session.progress).to eq(0)
    end

    it "ignores skipped sets when reporting how much is done" do
      be = create(:block_exercise, program_block: create(:program_block, program_day: day))
      create(:prescribed_set, block_exercise: be, set_number: 1)
      create(:prescribed_set, block_exercise: be, set_number: 2)

      create(:set_log, session: session, block_exercise: be, set_number: 1)
      create(:set_log, session: session, block_exercise: be, set_number: 2, skipped: true)

      expect(session.logged_set_count).to eq(1)
      expect(session.progress).to eq(50)
    end
  end

  describe "#total_volume" do
    let(:block) { create(:program_block, program_day: day) }

    it "counts a per-side prescription twice, because the reps happen on each side" do
      per_side = create(:block_exercise, program_block: block, per_side: true)
      create(:set_log, session: session, block_exercise: per_side,
                       exercise: per_side.exercise, reps_completed: 10, load_value: 20)

      expect(session.total_volume).to eq(400)
    end

    it "skips a set with no load rather than treating it as zero-times-nil" do
      be = create(:block_exercise, program_block: block)
      create(:set_log, session: session, block_exercise: be, exercise: be.exercise,
                       reps_completed: 10, load_value: nil)

      expect { session.total_volume }.not_to raise_error
      expect(session.total_volume).to eq(0)
    end
  end
end
