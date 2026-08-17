require "rails_helper"

# Copy-on-assign is the decision this whole step rests on: structure is reused,
# prescription is tailored, and an assignment always pins a frozen version so a
# client's plan cannot shift under them.
RSpec.describe Program, "#assign_to!" do
  let(:practitioner) { create(:practitioner) }
  let(:client)       { create(:client, name: "Sebastián Zapata") }
  let(:other_client) { create(:client, name: "Otro Cliente") }

  # a published program with one week, one day, one exercise, one set
  def publish_program(template: false)
    program = create(:program, practitioner: practitioner, template: template)
    version = create(:program_version, program: program)
    week    = create(:program_week, program_version: version)
    day     = create(:program_day, program_week: week)
    block   = create(:program_block, program_day: day)
    be      = create(:block_exercise, program_block: block)
    create(:prescribed_set, block_exercise: be, load_value: 25)
    version.publish!
    program
  end

  context "an ordinary program" do
    it "assigns the published version directly" do
      program = publish_program
      assignment = program.assign_to!(client: client)

      expect(assignment.program_version).to eq(program.published_version)
      expect(assignment.client).to eq(client)
      expect(Program.count).to eq(1)
    end

    it "lets two clients share one version" do
      program = publish_program
      a = program.assign_to!(client: client)
      b = program.assign_to!(client: other_client)

      expect(a.program_version).to eq(b.program_version)
    end
  end

  context "a template" do
    it "creates a client-specific copy rather than sharing" do
      template = publish_program(template: true)

      expect { template.assign_to!(client: client) }.to change(Program, :count).by(1)

      copy = Program.order(:id).last
      expect(copy.template).to be(false)
      expect(copy.source_program).to eq(template)
      expect(copy.name).to include("Sebastián Zapata")
    end

    it "copies the whole prescription tree into the client's program" do
      template = publish_program(template: true)
      assignment = template.assign_to!(client: client)

      sets = PrescribedSet.joins(block_exercise: { program_block: { program_day: :program_week } })
                          .where(program_weeks: { program_version_id: assignment.program_version_id })
      expect(sets.count).to eq(1)
      expect(sets.first.load_value.to_i).to eq(25)
    end

    # The point of copying: adjusting one client's load must not touch another's.
    it "isolates each client's loads" do
      template = publish_program(template: true)
      first  = template.assign_to!(client: client)
      second = template.assign_to!(client: other_client)

      expect(first.program_version).not_to eq(second.program_version)

      set = PrescribedSet.joins(block_exercise: { program_block: { program_day: :program_week } })
                         .find_by(program_weeks: { program_version_id: first.program_version_id })
      set.update!(load_value: 60)

      other = PrescribedSet.joins(block_exercise: { program_block: { program_day: :program_week } })
                           .find_by(program_weeks: { program_version_id: second.program_version_id })
      expect(other.load_value.to_i).to eq(25)
    end

    it "leaves the template itself untouched and still a template" do
      template = publish_program(template: true)
      before = template.published_version

      template.assign_to!(client: client)

      expect(template.reload.template).to be(true)
      expect(template.published_version).to eq(before)
    end

    it "publishes the client copy so it is immediately usable" do
      template = publish_program(template: true)
      assignment = template.assign_to!(client: client)

      expect(assignment.program_version.status).to eq("published")
      expect(assignment.program_version.published_at).to be_present
    end
  end

  it "refuses when nothing is published" do
    program = create(:program, practitioner: practitioner)
    create(:program_version, program: program)

    expect { program.assign_to!(client: client) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
