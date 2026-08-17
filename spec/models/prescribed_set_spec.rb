require "rails_helper"

RSpec.describe PrescribedSet do
  describe "which inputs the client is asked for" do
    # Driven by the prescription rather than a blanket rule, so a bodyweight
    # movement the practitioner DID put an RPE on still asks for one.
    it "asks for a load only when there is a number to type" do
      expect(build(:prescribed_set, load_kind: "external")).to be_logs_load
      expect(build(:prescribed_set, load_kind: "machine")).to be_logs_load
      expect(build(:prescribed_set, load_kind: "bodyweight")).not_to be_logs_load
      expect(build(:prescribed_set, load_kind: "none")).not_to be_logs_load
      # A band is chosen equipment, not a quantity.
      expect(build(:prescribed_set, load_kind: "band")).not_to be_logs_load
    end

    it "asks for RPE only when a target was prescribed" do
      expect(build(:prescribed_set, target_rpe: 8)).to be_logs_rpe
      expect(build(:prescribed_set, target_rpe: nil)).not_to be_logs_rpe
    end
  end

  describe "#load_summary" do
    it "translates bodyweight rather than leaking the enum value" do
      set = build(:prescribed_set, load_kind: "bodyweight", load_value: nil)

      I18n.with_locale(:es) { expect(set.load_summary).to eq("Peso corporal") }
      I18n.with_locale(:en) { expect(set.load_summary).to eq("Bodyweight") }
    end

    it "renders a load range for a 15/20/25 lb scheme" do
      set = build(:prescribed_set, load_kind: "external",
                                   load_value: 20, load_value_max: 25, load_unit: "lb")

      expect(set.load_summary).to eq("20/25 lb")
    end

    it "returns nothing at all when there is no load" do
      expect(build(:prescribed_set, load_kind: "none").load_summary).to be_nil
    end
  end

  describe "#prescription_summary" do
    it "collapses a rep range down to one number when min and max match" do
      expect(build(:prescribed_set, reps_min: 10, reps_max: 10).prescription_summary).to eq("10")
      expect(build(:prescribed_set, reps_min: 6,  reps_max: 8).prescription_summary).to eq("6-8")
      expect(build(:prescribed_set, reps_min: 12, reps_max: nil).prescription_summary).to eq("12")
    end
  end

  describe "drop segments" do
    it "treats a second segment of the same set as a drop" do
      expect(build(:prescribed_set, segment_number: 1)).not_to be_drop_segment
      expect(build(:prescribed_set, segment_number: 2)).to be_drop_segment
    end
  end
end
