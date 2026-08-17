require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let!(:day)       { create(:program_day, program_week: week, position: 1) }
  let(:block)      { create(:program_block, program_day: day) }
  let!(:slot)        { create(:block_exercise, program_block: block) }
  let!(:pset)      { create(:prescribed_set, block_exercise: slot, set_number: 1, rest_seconds: 180) }

  describe "POST /sessions" do
    before { sign_in_as(client) }

    it "starts the next day and lands on the runner" do
      expect { post sessions_path }.to change(Session, :count).by(1)

      session = Session.last
      expect(session.program_day).to eq(day)
      expect(session.status).to eq("in_progress")
      expect(response).to redirect_to(session)
    end

    # A phone in a gym gets locked, backgrounded and reopened constantly. The
    # second tap must resume, not create a parallel session.
    it "resumes the existing session instead of opening a second one" do
      post sessions_path
      first = Session.last

      expect { post sessions_path, params: { program_day_id: day.id } }
        .not_to change(Session, :count)
      expect(response).to redirect_to(first)
    end

    it "refuses a day belonging to somebody else's program" do
      foreign_day = create(:program_day)

      post sessions_path, params: { program_day_id: foreign_day.id }

      # Falls back to this client's own next day rather than starting a
      # stranger's workout.
      expect(Session.last.program_day).to eq(day)
    end

    it "sends a client with no active program back to the dashboard" do
      other = create(:client)
      sign_in_as(other)

      post sessions_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /sessions/:id" do
    let!(:session) { create(:session, program_assignment: assignment, program_day: day) }

    before { sign_in_as(client) }

    it "renders the runner with the prescription on screen" do
      get session_path(session)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(slot.exercise.name_es)
      expect(response.body).to include("Serie 1 de 1")
    end

    # The bug that hard-deleted a record: a button_to inside a form_with makes
    # the browser drop the inner form and hand its _method to the outer one.
    it "renders no nested forms" do
      get session_path(session)

      expect(response.body).to have_no_nested_forms
    end

    it "shows what was done last time for the same exercise" do
      earlier = create(:session, program_assignment: assignment,
                                 program_day: create(:program_day, program_week: week, position: 2))
      travel_to(2.days.ago) do
        create(:set_log, session: earlier, block_exercise: slot, exercise: slot.exercise,
                         reps_completed: 8, load_value: 20, load_unit: "lb", rpe_reported: 7)
      end

      get session_path(session)

      expect(response.body).to include("La vez pasada")
      expect(response.body).to include("8 × 20 lb · RPE 7")
    end

    it "renders exercises nested inside a paired block" do
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      child  = create(:program_block, program_day: day, parent_block: parent)
      nested = create(:block_exercise, program_block: child)
      create(:prescribed_set, block_exercise: nested, set_number: 1)

      get session_path(session)

      expect(response.body).to include(nested.exercise.name_es)
    end

    describe "the runner layout" do
      let!(:second) { create(:block_exercise, program_block: block) }
      before { create(:prescribed_set, block_exercise: second, set_number: 1) }

      it "renders one panel per exercise, all hidden until the runner opens one" do
        get session_path(session)

        expect(response.body).to include(%(id="ex-#{slot.id}"))
        expect(response.body).to include(%(id="ex-#{second.id}"))
        expect(response.body.scan(/data-runner-target="panel"/).size).to eq(2)
      end

      it "shows the exercise counter, not a set counter" do
        get session_path(session)

        expect(response.body).to match(/data-runner-target="counter"[^>]*>\s*1 \/ 2/)
      end

      it "collapses the sets you are not on into a single line each" do
        create(:prescribed_set, block_exercise: slot, set_number: 2)

        get session_path(session)

        expect(response.body).to include("data-collapsed")
        expect(response.body).to include("Serie 2")
      end
    end

    # The runner once rendered every exercise hidden and relied on Stimulus to
    # reveal one. When the JS did not boot, the client got a header, two nav
    # buttons and no workout. A gym screen must not need JavaScript to show
    # anything.
    describe "without JavaScript" do
      let!(:second) { create(:block_exercise, program_block: block) }
      before { create(:prescribed_set, block_exercise: second, set_number: 1) }

      it "leaves exactly one exercise visible" do
        get session_path(session)

        panels = response.body.scan(/<section[^>]*data-runner-target="panel"[^>]*>/)
        expect(panels.size).to eq(2)
        expect(panels.count { |tag| !tag.include?("hidden") }).to eq(1)
      end

      it "opens the first exercise that still has sets to log" do
        create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                         set_number: 1)

        get session_path(session)
        open_panel = response.body[/<section[^>]*data-runner-target="panel"(?![^>]*hidden)[^>]*>/]

        expect(open_panel).to include(%(id="ex-#{second.id}"))
      end

      it "honours ?ex= so the nav links work as plain links" do
        get session_path(session, ex: 1)
        open_panel = response.body[/<section[^>]*data-runner-target="panel"(?![^>]*hidden)[^>]*>/]

        expect(open_panel).to include(%(id="ex-#{second.id}"))
      end

      it "clamps an out-of-range ?ex= instead of rendering an empty runner" do
        get session_path(session, ex: 999)

        expect(response).to have_http_status(:ok)
        expect(response.body.scan(/data-runner-target="panel"(?![^>]*hidden)/).size).to eq(1)
      end

      it "renders the nav as links carrying the next index" do
        get session_path(session)

        expect(response.body).to include(session_path(session, ex: 1, anchor: "ex-#{second.id}"))
      end

      it "renders the set chips as links, so switching sets needs no JS" do
        create(:prescribed_set, block_exercise: slot, set_number: 2)

        get session_path(session)

        expect(response.body).to include(session_path(session, ex: 0, set: 2, anchor: "ex-#{slot.id}"))
      end

      it "honours ?set= on the open exercise" do
        create(:prescribed_set, block_exercise: slot, set_number: 2)

        get session_path(session, ex: 0, set: 2)

        # The requested set is the expanded one, so its collapsed line is hidden.
        expect(response.body).to match(/data-key="2"[^>]*>.*?data-collapsed[^>]*hidden/m)
      end
    end

    describe "bodyweight prescriptions" do
      let(:bw_block) { create(:program_block, program_day: day) }
      let!(:bw)      { create(:block_exercise, program_block: bw_block) }

      before do
        create(:prescribed_set, block_exercise: bw, set_number: 1,
                                load_kind: "bodyweight", load_value: nil,
                                load_unit: nil, target_rpe: nil)
        get session_path(session)
      end

      # Nothing to weigh, and Cristian does not put RPE on bodyweight work.
      it "asks for reps only" do
        panel = response.body[/id="ex-#{bw.id}".*?<\/section>/m]

        expect(panel).to include("reps_completed")
        expect(panel).not_to include("load_value")
        expect(panel).not_to include("rpe_reported")
      end

      it "says peso corporal rather than the English enum value" do
        expect(response.body).to include("Peso corporal")
        expect(response.body).not_to include(">bodyweight<")
      end

      it "still asks for RPE when the practitioner prescribed one" do
        rpe_be = create(:block_exercise, program_block: bw_block)
        create(:prescribed_set, block_exercise: rpe_be, set_number: 1,
                                load_kind: "bodyweight", load_value: nil,
                                load_unit: nil, target_rpe: 8)

        get session_path(session)
        panel = response.body[/id="ex-#{rpe_be.id}".*?<\/section>/m]

        expect(panel).to include("rpe_reported")
        expect(panel).not_to include("load_value")
      end
    end

    it "does not let a client open somebody else's session" do
      intruder = create(:client)
      sign_in_as(intruder)

      with_production_error_pages { get session_path(session) }

      expect(response).to have_http_status(:not_found)
    end

    it "sends a signed-out visitor to the sign-in page" do
      delete destroy_user_session_path
      get session_path(session)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /sessions/:id/complete" do
    let!(:session) { create(:session, program_assignment: assignment, program_day: day) }

    before { sign_in_as(client) }

    it "marks the session done" do
      patch complete_session_path(session)

      expect(session.reload.status).to eq("completed")
      expect(session.completed_at).to be_present
      expect(response).to redirect_to(session)
    end

    it "refuses to complete a session that is not yours" do
      sign_in_as(create(:client))

      with_production_error_pages { patch complete_session_path(session) }

      expect(response).to have_http_status(:not_found)
      expect(session.reload.status).not_to eq("completed")
    end
  end
end
