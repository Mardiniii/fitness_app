require "rails_helper"

RSpec.describe ProgramVersion do
  describe "#publish!" do
    it "refuses a version with no weeks" do
      version = create(:program_version)
      expect { version.publish! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(version.reload).to be_draft
    end

    it "archives the previously published version" do
      program = create(:program)
      old = create(:program_version, program: program, status: "published")
      new_version = create(:program_version, program: program)
      create(:program_week, program_version: new_version)

      new_version.publish!

      expect(old.reload.status).to eq("archived")
      expect(new_version.reload.status).to eq("published")
      expect(new_version.published_at).to be_present
    end

    it "leaves other programs' published versions alone" do
      other = create(:program_version, status: "published")
      version = create(:program_version)
      create(:program_week, program_version: version)

      version.publish!

      expect(other.reload.status).to eq("published")
    end
  end

  describe "#duplicate_as_draft!" do
    it "creates a draft with the next version number" do
      version = create(:program_version, status: "published")
      create(:program_week, program_version: version)

      draft = version.duplicate_as_draft!

      expect(draft).to be_draft
      expect(draft.version_number).to eq(version.version_number + 1)
      expect(draft.program).to eq(version.program)
    end

    it "does not touch the source version" do
      version = create(:program_version, status: "published")
      create(:program_week, program_version: version)

      expect { version.duplicate_as_draft! }
        .not_to change { version.reload.program_weeks.count }
      expect(version.reload.status).to eq("published")
    end
  end

  describe "#editable?" do
    it "is true only for drafts" do
      expect(build(:program_version, status: "draft")).to be_editable
      expect(build(:program_version, status: "published")).not_to be_editable
      expect(build(:program_version, status: "archived")).not_to be_editable
    end
  end
end
