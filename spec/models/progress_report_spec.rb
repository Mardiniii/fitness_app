require "rails_helper"

RSpec.describe ProgressReport do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let(:day)        { create(:program_day, program_week: week, position: 1) }
  let(:block)      { create(:program_block, program_day: day) }
  let(:slot)       { create(:block_exercise, program_block: block) }

  def logged_session(at:, load:, reps: 10, exercise_slot: slot)
    session = create(:session, program_assignment: assignment, program_day: day,
                               status: "completed", completed_at: at)
    create(:set_log, session: session, block_exercise: exercise_slot,
                     exercise: exercise_slot.exercise, reps_completed: reps,
                     load_value: load, load_unit: "lb", completed_at: at)
    session
  end

  describe "#exercise_trends" do
    it "reports the change in best load between the first and latest session" do
      logged_session(at: 3.weeks.ago, load: 20)
      logged_session(at: 1.week.ago,  load: 25)

      trend = described_class.new(client: client).exercise_trends.first

      expect(trend.exercise).to eq(slot.exercise)
      expect(trend.sessions).to eq(2)
      expect(trend.first_point.best_load).to eq(20)
      expect(trend.last_point.best_load).to eq(25)
      expect(trend.change_pct).to eq(25)
    end

    # One session is not a trend. Reporting 0% would read as "no progress"
    # rather than "nothing to compare yet".
    it "returns no percentage when there is only one session" do
      logged_session(at: 1.week.ago, load: 20)

      expect(described_class.new(client: client).exercise_trends.first.change_pct).to be_nil
    end

    it "takes the heaviest set of a session, not the last one" do
      session = create(:session, program_assignment: assignment, program_day: day,
                                 status: "completed", completed_at: 1.week.ago)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       set_number: 1, load_value: 30, completed_at: 1.week.ago)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       set_number: 2, load_value: 20, completed_at: 1.week.ago)

      point = described_class.new(client: client).exercise_trends.first.last_point
      expect(point.best_load).to eq(30)
    end

    it "counts a per-side prescription twice in volume" do
      per_side = create(:block_exercise, program_block: block, per_side: true)
      logged_session(at: 1.week.ago, load: 10, reps: 10, exercise_slot: per_side)

      trend = described_class.new(client: client).exercise_trends
                             .find { |t| t.exercise == per_side.exercise }

      expect(trend.last_point.volume).to eq(200)
    end

    it "ignores another client's logs entirely" do
      logged_session(at: 1.week.ago, load: 20)
      stranger = create(:client)

      expect(described_class.new(client: stranger).exercise_trends).to be_empty
    end

    it "skips skipped sets" do
      session = create(:session, program_assignment: assignment, program_day: day,
                                 status: "completed", completed_at: 1.week.ago)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       skipped: true, load_value: 99, completed_at: 1.week.ago)

      expect(described_class.new(client: client).exercise_trends).to be_empty
    end
  end

  describe "#session_history" do
    it "returns one entry per week, including the weeks with nothing in them" do
      logged_session(at: 1.week.ago, load: 20)

      history = described_class.new(client: client).session_history(weeks: 4)

      expect(history.size).to eq(4)
      expect(history.sum { |h| h[:sessions] }).to eq(1)
      expect(history.map { |h| h[:week_of] }).to eq(history.map { |h| h[:week_of] }.sort)
    end
  end

  describe "#any_data?" do
    it "is false for a client who has done nothing yet" do
      expect(described_class.new(client: client).any_data?).to be(false)
    end

    it "is true once a check-in exists, even with no sessions" do
      create(:check_in, client: client)

      expect(described_class.new(client: client).any_data?).to be(true)
    end
  end
end
