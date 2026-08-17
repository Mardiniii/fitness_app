require "rails_helper"

# Every case here is a real line from Cristian's plans. If the builder cannot
# express one, he cannot author that plan in the app.
RSpec.describe PrescriptionBuilder do
  let(:block_exercise) { create(:block_exercise) }

  def build(params) = described_class.new(block_exercise, ActionController::Parameters.new(params).permit!)

  describe "uniform mode" do
    # "Press de Banca con mancuernas · 3 · 10 · 3 min · RPE 9/50lb"
    it "expands one row into N identical sets" do
      build(mode: "uniform", set_count: "3", uniform: {
        measure_kind: "reps", reps_min: "10", target_rpe: "9",
        rest_seconds: "180", load_kind: "external", load_value: "50", load_unit: "lb"
      }).save!

      sets = block_exercise.prescribed_sets.order(:set_number)
      expect(sets.count).to eq(3)
      expect(sets.map(&:set_number)).to eq([ 1, 2, 3 ])
      expect(sets.map { |s| s.load_value.to_i }).to all(eq(50))
      expect(sets.first.target_rpe.to_f).to eq(9.0)
    end

    # "Press banco inclinado con mancuernas · 6-8 · RPE 9/40lb"
    it "keeps a rep range" do
      build(mode: "uniform", set_count: "3",
            uniform: { measure_kind: "reps", reps_min: "6", reps_max: "8" }).save!

      set = block_exercise.prescribed_sets.first
      expect([ set.reps_min, set.reps_max ]).to eq([ 6, 8 ])
    end

    # "Plancha sostenida sobre fitball · 30 seg"
    it "handles time-based work" do
      build(mode: "uniform", set_count: "3",
            uniform: { measure_kind: "time", work_seconds: "30" }).save!

      expect(block_exercise.prescribed_sets.first.work_seconds).to eq(30)
      expect(block_exercise.prescribed_sets.first.measure_kind).to eq("time")
    end
  end

  describe "per-set mode" do
    # "Aproximaciones bench press · 10-10-10 · RPE 6/25-30-35lb"
    it "stores a different load for each set" do
      build(mode: "per_set", sets: {
        "0" => { measure_kind: "reps", reps_min: "10", load_kind: "external", load_value: "25", load_unit: "lb" },
        "1" => { measure_kind: "reps", reps_min: "10", load_kind: "external", load_value: "30", load_unit: "lb" },
        "2" => { measure_kind: "reps", reps_min: "10", load_kind: "external", load_value: "35", load_unit: "lb" }
      }).save!

      expect(block_exercise.prescribed_sets.order(:set_number).map { |s| s.load_value.to_i })
        .to eq([ 25, 30, 35 ])
    end

    # "15-12-10 Bench press barra 15/20/25lb"
    it "stores a descending rep scheme" do
      build(mode: "per_set", sets: {
        "0" => { measure_kind: "reps", reps_min: "15", load_kind: "external", load_value: "15" },
        "1" => { measure_kind: "reps", reps_min: "12", load_kind: "external", load_value: "20" },
        "2" => { measure_kind: "reps", reps_min: "10", load_kind: "external", load_value: "25" }
      }).save!

      expect(block_exercise.prescribed_sets.order(:set_number).map(&:reps_min)).to eq([ 15, 12, 10 ])
    end

    # "Drop set en sentadilla bulgara · 12+12 · RPE 9/40lb"
    it "adds a second segment for a drop set" do
      build(mode: "per_set", sets: {
        "0" => { measure_kind: "reps", reps_min: "12", load_kind: "external",
                 load_value: "40", drop_reps: "12", drop_load: "30" }
      }).save!

      segments = block_exercise.prescribed_sets.where(set_number: 1).order(:segment_number)
      expect(segments.map(&:segment_number)).to eq([ 1, 2 ])
      expect(segments.map { |s| s.load_value.to_i }).to eq([ 40, 30 ])
    end

    it "carries the base load into the drop when none is given" do
      build(mode: "per_set", sets: {
        "0" => { measure_kind: "reps", reps_min: "12", load_kind: "external",
                 load_value: "40", drop_reps: "10" }
      }).save!

      expect(block_exercise.prescribed_sets.find_by(segment_number: 2).load_value.to_i).to eq(40)
    end
  end

  describe "rebuilding" do
    it "replaces the previous prescription rather than appending" do
      create(:prescribed_set, block_exercise: block_exercise, set_number: 1)
      create(:prescribed_set, block_exercise: block_exercise, set_number: 2)

      build(mode: "uniform", set_count: "1", uniform: { measure_kind: "reps", reps_min: "8" }).save!

      expect(block_exercise.prescribed_sets.count).to eq(1)
    end

    # Blank strings from empty form fields would otherwise violate the
    # measure-kind check constraint.
    it "treats blank inputs as nil" do
      builder = build(mode: "uniform", set_count: "1",
                      uniform: { measure_kind: "reps", reps_min: "10", reps_max: "",
                                 target_rpe: "", load_value: "", rest_seconds: "" })

      expect(builder.save!).to be(true)
      set = block_exercise.prescribed_sets.first
      expect(set.reps_max).to be_nil
      expect(set.target_rpe).to be_nil
    end

    it "reports a failure instead of raising" do
      builder = build(mode: "uniform", set_count: "1",
                      uniform: { measure_kind: "reps", reps_min: "" })

      expect(builder.save!).to be(false)
      expect(builder.error).to be_present
    end
  end
end
