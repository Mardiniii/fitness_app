require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let!(:day)       { create(:program_day, program_week: week, position: 1) }

  before { sign_in_as(client) }

  it "offers the next day when there is one" do
    get root_path

    expect(response.body).to include(I18n.t("dashboard.start_session"))
    expect(response.body).to include(day.display_name)
  end

  it "offers to resume a session left in progress" do
    session = create(:session, program_assignment: assignment, program_day: day,
                               status: "in_progress")

    get root_path

    expect(response.body).to include(I18n.t("dashboard.resume_session"))
    expect(response.body).to include(session_path(session))
    expect(response.body).not_to include(I18n.t("dashboard.start_session"))
  end

  # Every day in the assigned version is done. Offering "Empezar sesión" here
  # would start a day that does not exist.
  it "stops offering a session once the whole program is finished" do
    create(:session, program_assignment: assignment, program_day: day, status: "completed",
                     completed_at: 1.day.ago)

    get root_path

    expect(response.body).to include(I18n.t("dashboard.program_complete"))
    expect(response.body).not_to include(I18n.t("dashboard.start_session"))
    expect(response.body).to include(progress_path)
  end

  it "distinguishes a finished program from having no program at all" do
    other = create(:client)
    sign_in_as(other)

    get root_path

    expect(response.body).to include(I18n.t("dashboard.no_program"))
    expect(response.body).not_to include(I18n.t("dashboard.program_complete"))
  end

  it "prompts for a check-in when this week has none" do
    get root_path

    expect(response.body).to include(I18n.t("dashboard.do_check_in"))
  end

  it "stops prompting once this week is logged" do
    create(:check_in, client: client, week_of: Date.current.beginning_of_week)

    get root_path

    expect(response.body).not_to include(I18n.t("dashboard.do_check_in"))
  end

  describe "the practitioner roster" do
    let(:practitioner) { create(:practitioner) }

    before do
      create(:practitioner_client, practitioner: practitioner, client: client)
      create(:session, program_assignment: assignment, program_day: day,
                       status: "completed", completed_at: 2.days.ago)
      sign_in_as(practitioner)
    end

    # These were hardcoded "0/0" and "0" placeholders that shipped as if they
    # were real, which is worse than showing nothing.
    it "shows real session counts rather than placeholders" do
      get root_path

      expect(response.body).to include("1/1")
      expect(response.body).not_to include("0/0")
    end

    it "links each client to their detail page" do
      get root_path

      expect(response.body).to include(client_path(client))
    end
  end
end
