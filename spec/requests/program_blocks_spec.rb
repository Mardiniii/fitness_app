require "rails_helper"

RSpec.describe "Program blocks", type: :request do
  let(:practitioner) { create(:practitioner) }
  let(:program)      { create(:program, practitioner: practitioner) }
  let(:version)      { create(:program_version, program: program) }
  let(:week)         { create(:program_week, program_version: version) }
  let(:day)          { create(:program_day, program_week: week) }

  before { sign_in_as(practitioner) }

  describe "GET /program_days/:id" do
    it "renders the block editor with no nested forms" do
      block = create(:program_block, program_day: day)
      be = create(:block_exercise, program_block: block)
      create(:prescribed_set, block_exercise: be)

      get program_day_path(day)

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_no_nested_forms
    end

    it "renders nested paired blocks without nested forms" do
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      create(:program_block, program_day: day, parent_block: parent, name: "Bloque A")

      get program_day_path(day)

      expect(response.body).to include("Bloque A")
      expect(response.body).to have_no_nested_forms
    end
  end

  # The "Añadir" control produced no HTTP request at all, so the question is
  # whether the form renders, and whether the submit button is genuinely inside
  # it. Nokogiri answers both -- and unlike the browser, it will not silently
  # reparent a stray button.
  describe "the add-exercise form on the day page" do
    let!(:block) { create(:program_block, program_day: day, execution_mode: "straight_sets") }
    let!(:exercise) { create(:exercise, name_es: "Sentadilla con barra libre") }

    def form_for_block(body, block)
      Nokogiri::HTML(body).css("form").find do |f|
        f["action"] == "/program_blocks/#{block.id}/block_exercises"
      end
    end

    it "renders a form posting to the right path" do
      get program_day_path(day)
      form = form_for_block(response.body, block)

      expect(form).to be_present, "no form posting to /program_blocks/#{block.id}/block_exercises"
      expect(form["method"]).to eq("post")
    end

    it "puts the select and the submit button inside that form" do
      get program_day_path(day)
      form = form_for_block(response.body, block)

      expect(form.css("select[name=exercise_id]")).to be_present
      expect(form.css("input[type=submit], button[type=submit]")).to be_present
    end

    it "offers the library as options" do
      get program_day_path(day)
      form = form_for_block(response.body, block)

      expect(form.css("select[name=exercise_id] option").map(&:text))
        .to include("Sentadilla con barra libre")
    end

    it "does not render the form on a paired block, which holds sub-blocks instead" do
      paired = create(:program_block, program_day: day, execution_mode: "paired")
      get program_day_path(day)

      expect(form_for_block(response.body, paired)).to be_nil
    end
  end

  describe "creating blocks and exercises" do
    it "appends a block with a sensible default" do
      expect { post program_day_program_blocks_path(day) }.to change(ProgramBlock, :count).by(1)
      expect(ProgramBlock.last.execution_mode).to eq("straight_sets")
    end

    it "adds a child block only under a paired parent" do
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      expect { post add_child_program_block_path(parent) }.to change(ProgramBlock, :count).by(1)
      expect(ProgramBlock.last.parent_block).to eq(parent)
    end

    # A new row must never be blank, or the editor shows an exercise with no
    # prescription and the client sees nothing to do.
    it "seeds one prescribed set when an exercise is added" do
      block = create(:program_block, program_day: day)
      exercise = create(:exercise)

      post program_block_block_exercises_path(block), params: { exercise_id: exercise.id }

      be = BlockExercise.last
      expect(be.exercise).to eq(exercise)
      expect(be.prescribed_sets.count).to eq(1)
    end
  end

  describe "reordering" do
    it "swaps adjacent exercises" do
      block = create(:program_block, program_day: day)
      first  = create(:block_exercise, program_block: block, position: 1)
      second = create(:block_exercise, program_block: block, position: 2)

      post move_block_exercise_path(second, direction: "up")

      expect(first.reload.position).to eq(2)
      expect(second.reload.position).to eq(1)
    end

    it "is a no-op at the boundary" do
      block = create(:program_block, program_day: day)
      only = create(:block_exercise, program_block: block, position: 1)

      post move_block_exercise_path(only, direction: "up")

      expect(only.reload.position).to eq(1)
    end
  end

  describe "a published version" do
    let(:version) { create(:program_version, program: program, status: "published") }

    it "refuses block creation" do
      expect { post program_day_program_blocks_path(day) }.not_to change(ProgramBlock, :count)
      expect(flash[:alert]).to be_present
    end

    it "refuses adding an exercise" do
      block = create(:program_block, program_day: day)
      expect { post program_block_block_exercises_path(block), params: { exercise_id: create(:exercise).id } }
        .not_to change(BlockExercise, :count)
    end
  end

  describe "another practitioner's day" do
    it "is not reachable" do
      theirs = create(:program_day,
                      program_week: create(:program_week,
                                           program_version: create(:program_version)))
      get program_day_path(theirs)
      expect(response).to have_http_status(:not_found)
    end
  end
end
