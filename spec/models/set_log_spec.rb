require "rails_helper"

RSpec.describe SetLog do
  let(:assignment) { create(:program_assignment) }
  let(:day)        { create(:program_day, program_week: create(:program_week, program_version: assignment.program_version)) }
  let(:session)    { create(:session, program_assignment: assignment, program_day: day) }
  let(:block)      { create(:program_block, program_day: day) }
  let(:slot)         { create(:block_exercise, program_block: block) }

  describe "client_uuid" do
    # Regression: the column defaults to gen_random_uuid() in Postgres, but
    # Rails cannot evaluate a function default before the INSERT. The record
    # reached the presence validation with nil, so NO set log could ever save.
    it "is generated on save when the client did not supply one" do
      log = described_class.new(session: session, block_exercise: slot, exercise: slot.exercise,
                                set_number: 1, segment_number: 1, reps_completed: 10)

      expect(log.save).to slot(true), -> { log.errors.full_messages.to_sentence }
      expect(log.client_uuid).to be_present
    end

    it "keeps the identifier the phone generated, so a replay is idempotent" do
      uuid = SecureRandom.uuid
      log = create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                             client_uuid: uuid)

      expect(log.reload.client_uuid).to eq(uuid)
    end

    it "refuses two rows with the same identifier" do
      uuid = SecureRandom.uuid
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       set_number: 1, client_uuid: uuid)

      dup = build(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                            set_number: 2, client_uuid: uuid)

      expect(dup).not_to be_valid
      expect(dup.errors[:client_uuid]).to be_present
    end
  end

  describe "substitutions" do
    it "accepts a movement the practitioner actually listed" do
      alternative = create(:exercise)
      create(:block_exercise_alternative_record, block_exercise: slot, exercise: alternative)

      log = build(:set_log, session: session, block_exercise: slot, exercise: alternative)

      expect(log).to be_valid
      expect(log).to be_substituted
    end

    it "rejects a movement nobody sanctioned" do
      log = build(:set_log, session: session, block_exercise: slot, exercise: create(:exercise))

      expect(log).not_to be_valid
      expect(log.errors[:exercise_id]).to be_present
    end

    it "does not flag the prescribed movement as a substitution" do
      expect(build(:set_log, session: session, block_exercise: slot, exercise: slot.exercise))
        .not_to be_substituted
    end
  end

  describe "#summary" do
    it "renders load without trailing zeros" do
      log = build(:set_log, block_exercise: slot, exercise: slot.exercise,
                            reps_completed: 8, load_value: 22.5, load_unit: "lb", rpe_reported: 8.0)

      expect(log.summary).to eq("8 × 22.5 lb · RPE 8")
    end

    it "omits the load entirely when there was none" do
      log = build(:set_log, block_exercise: slot, exercise: slot.exercise,
                            reps_completed: 15, load_value: nil, load_unit: nil, rpe_reported: nil)

      expect(log.summary).to eq("15")
    end
  end

  describe ".previous_for" do
    it "returns the most recent completed set first and ignores skipped ones" do
      old_log = nil
      recent  = nil
      travel_to(3.days.ago) do
        old_log = create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                                   set_number: 1, completed_at: Time.current)
      end
      travel_to(1.day.ago) do
        recent = create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                                  set_number: 2, completed_at: Time.current)
        create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                         set_number: 3, skipped: true, completed_at: Time.current)
      end

      result = described_class.previous_for(exercise_id: slot.exercise_id)

      expect(result.map(&:id)).to eq([ recent.id, old_log.id ])
    end
  end

  describe "rpe bounds" do
    it "rejects an RPE outside 1..10" do
      log = build(:set_log, session: session, block_exercise: slot, exercise: slot.exercise, rpe_reported: 12)
      expect(log).not_to be_valid
    end
  end
end
