require "rails_helper"

RSpec.describe "Set logs", type: :request do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let(:day)        { create(:program_day, program_week: week, position: 1) }
  let(:block)      { create(:program_block, program_day: day) }
  let(:slot)         { create(:block_exercise, program_block: block) }
  let!(:pset)      { create(:prescribed_set, block_exercise: slot, set_number: 1) }
  let(:session)    { create(:session, program_assignment: assignment, program_day: day) }

  def log_params(overrides = {})
    { block_exercise_id: slot.id, set_number: 1, segment_number: 1,
      reps_completed: 10, load_value: 22.5, load_unit: "lb", rpe_reported: 8 }.merge(overrides)
  end

  before { sign_in_as(client) }

  describe "POST /sessions/:session_id/set_logs" do
    # Regression: client_uuid is presence-validated but defaults to
    # gen_random_uuid() in the database, which Rails cannot evaluate before the
    # INSERT. Every single set submission used to fail validation silently.
    it "saves the set" do
      expect { post session_set_logs_path(session), params: log_params }
        .to change(SetLog, :count).by(1)

      log = SetLog.last
      expect(log.reps_completed).to eq(10)
      expect(log.load_value).to eq(22.5)
      expect(log.rpe_reported).to eq(8)
      expect(log.client_uuid).to be_present
      expect(flash[:alert]).to be_nil
      expect(response).to redirect_to(session_path(session, anchor: "ex-#{slot.id}"))
    end

    it "starts the session on the first logged set" do
      expect { post session_set_logs_path(session), params: log_params }
        .to change { session.reload.status }.from("pending").to("in_progress")
    end

    # The offline queue replays whatever it buffered. The natural key must
    # absorb the retry rather than writing the set twice.
    it "is idempotent when the same set is submitted again" do
      uuid = SecureRandom.uuid
      post session_set_logs_path(session), params: log_params(client_uuid: uuid)

      expect { post session_set_logs_path(session), params: log_params(client_uuid: uuid, reps_completed: 12) }
        .not_to change(SetLog, :count)

      expect(SetLog.last.reps_completed).to eq(12)
      expect(SetLog.last.client_uuid).to eq(uuid)
    end

    it "treats each drop-set segment as its own row" do
      post session_set_logs_path(session), params: log_params(segment_number: 1, reps_completed: 10)
      post session_set_logs_path(session), params: log_params(segment_number: 2, reps_completed: 8, load_value: 15)

      expect(session.set_logs.count).to eq(2)
      expect(session.set_logs.order(:segment_number).map(&:reps_completed)).to eq([ 10, 8 ])
    end

    it "records a substitution the practitioner listed" do
      alternative = create(:exercise)
      create(:block_exercise_alternative_record, block_exercise: slot, exercise: alternative)

      post session_set_logs_path(session), params: log_params(exercise_id: alternative.id)

      expect(SetLog.last.exercise_id).to eq(alternative.id)
      expect(SetLog.last).to be_substituted
    end

    # Silently recording an unsanctioned movement would corrupt the
    # progression history of two exercises at once.
    it "falls back to the prescribed movement when the substitution was never sanctioned" do
      rogue = create(:exercise)

      post session_set_logs_path(session), params: log_params(exercise_id: rogue.id)

      expect(SetLog.last.exercise_id).to eq(slot.exercise_id)
    end

    # Regression: the lookup used program_day.program_blocks, which is scoped
    # to top-level blocks, so an exercise inside a paired block 404'd.
    it "accepts an exercise nested inside a paired block" do
      parent = create(:program_block, program_day: day, execution_mode: "paired")
      child  = create(:program_block, program_day: day, parent_block: parent)
      nested = create(:block_exercise, program_block: child)
      create(:prescribed_set, block_exercise: nested, set_number: 1)

      post session_set_logs_path(session),
           params: log_params(block_exercise_id: nested.id)

      expect(response).to be_redirect
      expect(SetLog.last.block_exercise_id).to eq(nested.id)
    end

    describe "auto-advance" do
      it "stays on the exercise while it still has sets left" do
        create(:prescribed_set, block_exercise: slot, set_number: 2)

        post session_set_logs_path(session), params: log_params(set_number: 1)

        expect(response).to redirect_to(session_path(session, anchor: "ex-#{slot.id}"))
      end

      it "moves to the next exercise once the last set is logged" do
        following = create(:block_exercise, program_block: block)
        create(:prescribed_set, block_exercise: following, set_number: 1)

        post session_set_logs_path(session), params: log_params(set_number: 1)

        expect(response).to redirect_to(session_path(session, anchor: "ex-#{following.id}"))
      end

      it "stays put on the last exercise of the day" do
        post session_set_logs_path(session), params: log_params(set_number: 1)

        expect(response).to redirect_to(session_path(session, anchor: "ex-#{slot.id}"))
      end

      # A drop set is one set in two segments. The exercise is not finished
      # until both halves are in.
      it "does not advance until every segment of a drop set is logged" do
        create(:prescribed_set, block_exercise: slot, set_number: 1, segment_number: 2, reps_min: 8)
        following = create(:block_exercise, program_block: block)
        create(:prescribed_set, block_exercise: following, set_number: 1)

        post session_set_logs_path(session), params: log_params(segment_number: 1)
        expect(response).to redirect_to(session_path(session, anchor: "ex-#{slot.id}"))

        post session_set_logs_path(session), params: log_params(segment_number: 2)
        expect(response).to redirect_to(session_path(session, anchor: "ex-#{following.id}"))
      end
    end

    it "records a skipped set without counting it as work done" do
      post session_set_logs_path(session), params: log_params(skipped: "1")

      expect(SetLog.last.skipped).to slot(true)
      expect(session.reload.logged_set_count).to eq(0)
    end

    it "reports an invalid RPE instead of failing silently" do
      post session_set_logs_path(session), params: log_params(rpe_reported: 42)

      expect(SetLog.count).to eq(0)
      expect(response).to be_redirect

      follow_redirect!
      expect(response.body).to include("flash-alert")
    end

    it "refuses an exercise from a different day" do
      foreign = create(:block_exercise)

      with_production_error_pages do
        post session_set_logs_path(session), params: log_params(block_exercise_id: foreign.id)
      end

      expect(response).to have_http_status(:not_found)
      expect(SetLog.count).to eq(0)
    end

    it "refuses to write into somebody else's session" do
      sign_in_as(create(:client))

      with_production_error_pages do
        post session_set_logs_path(session), params: log_params
      end

      expect(response).to have_http_status(:not_found)
      expect(SetLog.count).to eq(0)
    end
  end
end
