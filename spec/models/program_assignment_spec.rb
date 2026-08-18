require "rails_helper"

RSpec.describe ProgramAssignment do
  let(:assignment) { create(:program_assignment) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let!(:day1)      { create(:program_day, program_week: week, position: 1) }
  let!(:day2)      { create(:program_day, program_week: week, position: 2) }

  describe "#next_program_day" do
    it "starts at the first day" do
      expect(assignment.next_program_day).to eq(day1)
    end

    # This used `select(:program_day_id)`, which yields Session records rather
    # than ids, so the comparison against day.id never matched and the first
    # day was returned forever.
    it "advances past a day that has been completed" do
      create(:session, program_assignment: assignment, program_day: day1,
                       status: "completed", completed_at: 1.day.ago)

      expect(assignment.next_program_day).to eq(day2)
    end

    it "returns nothing once every day is done" do
      [ day1, day2 ].each do |day|
        create(:session, program_assignment: assignment, program_day: day,
                         status: "completed", completed_at: 1.day.ago)
      end

      expect(assignment.next_program_day).to be_nil
    end

    it "does not count a session still in progress as done" do
      create(:session, program_assignment: assignment, program_day: day1,
                       status: "in_progress")

      expect(assignment.next_program_day).to eq(day1)
    end

    it "walks into the following week in order" do
      week2 = create(:program_week, program_version: assignment.program_version, position: 2)
      day3  = create(:program_day, program_week: week2, position: 1)

      [ day1, day2 ].each do |day|
        create(:session, program_assignment: assignment, program_day: day,
                         status: "completed", completed_at: 1.day.ago)
      end

      expect(assignment.next_program_day).to eq(day3)
    end
  end
end
