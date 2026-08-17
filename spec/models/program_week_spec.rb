require "rails_helper"

# The deep copy is the highest-risk code in the app: it is recursive, it runs
# in a transaction, and a silent omission (a dropped drop-set segment, a lost
# substitution) would corrupt a duplicated week without any visible error.
RSpec.describe ProgramWeek, "#duplicate!" do
  # A week exercising every structural case the real plans contain:
  #   - a paired parent block with two children  ("1 serie = bloque A + bloque B")
  #   - an exercise with a drop set              ("100lb + 10 con 70lb")
  #   - a stated substitution                    ("trx o pull up en Smith")
  let(:version) { create(:program_version) }
  let(:week)    { create(:program_week, program_version: version, position: 1) }
  let(:day)     { create(:program_day, program_week: week, position: 1) }
  let(:alternative_exercise) { create(:exercise, name_es: "Progresión pull up") }

  before do
    parent = create(:program_block, program_day: day, position: 1,
                                    execution_mode: "paired", round_count: 4, name: "Parte principal")
    child_a = create(:program_block, program_day: day, parent_block: parent,
                                     position: 1, name: "Bloque A", execution_mode: "circuit")
    create(:program_block, program_day: day, parent_block: parent,
                           position: 2, name: "Bloque B", execution_mode: "circuit")

    be = create(:block_exercise, program_block: child_a, position: 1,
                                 per_side: true, technique_notes: "Controla la bajada")
    # a drop set: one set_number, two segments
    create(:prescribed_set, block_exercise: be, set_number: 1, segment_number: 1,
                            reps_min: 10, load_value: 100)
    create(:prescribed_set, block_exercise: be, set_number: 1, segment_number: 2,
                            reps_min: 10, load_value: 70)
    create(:prescribed_set, block_exercise: be, set_number: 2, segment_number: 1,
                            reps_min: 12, load_value: 90)
    create(:block_exercise_alternative_record, block_exercise: be, exercise: alternative_exercise)
  end

  it "appends the copy after the last week" do
    copy = week.duplicate!
    expect(copy.position).to eq(2)
    expect(version.reload.program_weeks.count).to eq(2)
  end

  it "copies days" do
    copy = week.duplicate!
    expect(copy.program_days.count).to eq(1)
    expect(copy.program_days.first.focus).to eq(day.focus)
  end

  it "copies the nested block tree, preserving parentage" do
    copy = week.duplicate!
    copied_day = copy.program_days.first

    roots = copied_day.program_blocks.order(:position)
    expect(roots.count).to eq(1)
    expect(roots.first.execution_mode).to eq("paired")
    expect(roots.first.child_blocks.order(:position).map(&:name)).to eq([ "Bloque A", "Bloque B" ])
  end

  it "copies prescribed sets including drop-set segments" do
    copy = week.duplicate!
    be = copy.program_days.first.all_blocks
             .flat_map { |b| b.block_exercises.to_a }.first

    expect(be.prescribed_sets.count).to eq(3)
    first_set = be.prescribed_sets.where(set_number: 1).order(:segment_number)
    expect(first_set.map(&:segment_number)).to eq([ 1, 2 ])
    expect(first_set.map { |s| s.load_value.to_i }).to eq([ 100, 70 ])
  end

  it "copies per-side and technique notes" do
    copy = week.duplicate!
    be = copy.program_days.first.all_blocks
             .flat_map { |b| b.block_exercises.to_a }.first

    expect(be.per_side).to be(true)
    expect(be.technique_notes).to eq("Controla la bajada")
  end

  it "copies stated substitutions" do
    copy = week.duplicate!
    be = copy.program_days.first.all_blocks
             .flat_map { |b| b.block_exercises.to_a }.first

    expect(be.alternative_exercises).to eq([ alternative_exercise ])
  end

  # Guard against the class of bug where a new column is added to program_days
  # and quietly not carried across by the copy. Asserts by column list rather
  # than by naming fields, so it keeps working as the schema grows.
  it "copies every content column on the day, including the session video" do
    day.update!(
      name: "Día 1",
      focus: "TORSO",
      description: "Remata con cardio 20min",
      reference_url: "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view"
    )

    copied = week.duplicate!.program_days.first
    carried = ProgramDay.column_names - ProgramDay::COPY_EXCLUDED

    carried.each do |column|
      expect(copied.public_send(column)).to eq(day.public_send(column)),
        "expected #{column} to be carried into the duplicated day"
    end
    expect(copied.video.provider).to eq(:drive)
  end

  it "creates new records rather than moving the originals" do
    original_set_ids = PrescribedSet.pluck(:id)
    copy = week.duplicate!
    copied_ids = copy.program_days.first.all_blocks
                     .flat_map { |b| b.block_exercises.flat_map { |be| be.prescribed_sets.ids } }

    expect(copied_ids & original_set_ids).to be_empty
    expect(week.reload.program_days.first.all_blocks.count).to eq(3)
  end
end
