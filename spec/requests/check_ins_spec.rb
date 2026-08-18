require "rails_helper"

RSpec.describe "Check-ins", type: :request do
  let(:client) { create(:client) }

  before { sign_in_as(client) }

  describe "GET /check_ins/new" do
    it "renders a blank check-in for the current week" do
      get new_check_in_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.beginning_of_week.to_s)
    end

    # One row per week is enforced by a unique index. Handing the client a
    # blank form for a week they already logged would fail on save with a
    # message about uniqueness instead of just letting them edit it.
    it "redirects to the existing check-in when this week is already logged" do
      existing = create(:check_in, client: client, week_of: Date.current.beginning_of_week)

      get new_check_in_path

      expect(response).to redirect_to(edit_check_in_path(existing))
    end
  end

  describe "POST /check_ins" do
    it "saves the four fields" do
      expect {
        post check_ins_path, params: { check_in: {
          week_of: Date.current.beginning_of_week, bodyweight_kg: 77.5,
          feeling: 8, sleep_hours_avg: 7.5, notes: "Buena semana"
        } }
      }.to change(CheckIn, :count).by(1)

      check_in = CheckIn.last
      expect(check_in.client).to eq(client)
      expect(check_in.bodyweight_kg).to eq(77.5)
      expect(response).to redirect_to(check_ins_path)
    end

    it "re-renders with the error rather than losing what was typed" do
      post check_ins_path, params: { check_in: { week_of: Date.current, feeling: 42 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(CheckIn.count).to eq(0)
    end
  end

  describe "GET /check_ins" do
    it "lists this client's check-ins and nobody else's" do
      mine = create(:check_in, client: client, week_of: 1.week.ago.to_date.beginning_of_week,
                               notes: "Mi reporte")
      create(:check_in, notes: "Reporte ajeno")

      get check_ins_path

      expect(response.body).to include("Mi reporte")
      expect(response.body).not_to include("Reporte ajeno")
      expect(response.body).to include(edit_check_in_path(mine))
    end
  end

  describe "PATCH /check_ins/:id" do
    it "updates my own" do
      check_in = create(:check_in, client: client)

      patch check_in_path(check_in), params: { check_in: { bodyweight_kg: 76.2 } }

      expect(check_in.reload.bodyweight_kg).to eq(76.2)
    end

    it "cannot touch somebody else's" do
      stranger = create(:check_in, bodyweight_kg: 90)

      with_production_error_pages do
        patch check_in_path(stranger), params: { check_in: { bodyweight_kg: 10 } }
      end

      expect(response).to have_http_status(:not_found)
      expect(stranger.reload.bodyweight_kg).to eq(90)
    end
  end

  it "is behind authentication" do
    delete destroy_user_session_path
    get check_ins_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
