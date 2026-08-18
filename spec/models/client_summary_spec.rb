require "rails_helper"

RSpec.describe ClientSummary do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let!(:day1)      { create(:program_day, program_week: week, position: 1) }
  let!(:day2)      { create(:program_day, program_week: week, position: 2) }

  def completed(at, day: day1)
    create(:session, program_assignment: assignment, program_day: day,
                     status: "completed", completed_at: at)
  end

  describe "counts" do
    it "reports completed sessions against the days in the assigned version" do
      completed(2.days.ago)

      summary = described_class.new(client)

      expect(summary.sessions_done).to eq(1)
      expect(summary.sessions_total).to eq(2)
      expect(summary.completion_pct).to eq(50)
    end

    it "does not divide by zero for a program with no days" do
      empty = create(:client)
      create(:program_assignment, client: empty)

      expect(described_class.new(empty).completion_pct).to eq(0)
    end

    it "is all zeroes for a client with no program at all" do
      summary = described_class.new(create(:client))

      expect(summary.sessions_done).to eq(0)
      expect(summary.sessions_total).to eq(0)
      expect(summary.streak).to eq(0)
      expect(summary.days_since_last).to be_nil
    end
  end

  describe "#streak" do
    it "counts consecutive weeks that had a session" do
      completed(Date.current.beginning_of_week + 1.day)
      completed(1.week.ago, day: day2)

      expect(described_class.new(client).streak).to eq(2)
    end

    # Monday morning must not read as "you fell off" -- the current week has
    # not had a chance to happen yet.
    it "does not break the streak just because this week is still empty" do
      completed(1.week.ago)
      completed(2.weeks.ago, day: day2)

      expect(described_class.new(client).streak).to eq(2)
    end

    it "stops at the first missed week" do
      completed(1.week.ago)
      completed(4.weeks.ago, day: day2)

      expect(described_class.new(client).streak).to eq(1)
    end

    it "counts a week once even with several sessions in it" do
      completed(1.week.ago)
      completed(1.week.ago + 2.days, day: day2)

      expect(described_class.new(client).streak).to eq(1)
    end
  end

  describe "#stale?" do
    it "flags a client who has not trained in ten days" do
      completed(11.days.ago)

      summary = described_class.new(client)
      expect(summary.days_since_last).to eq(11)
      expect(summary).to be_stale
    end

    it "leaves a recent client alone" do
      completed(2.days.ago)

      expect(described_class.new(client)).not_to be_stale
    end

    it "treats a client who has never trained as needing attention" do
      expect(described_class.new(create(:client))).to be_stale
    end
  end
end
