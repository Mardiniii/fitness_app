require "rails_helper"

RSpec.describe "Client detail (practitioner)", type: :request do
  let(:practitioner) { create(:practitioner) }
  let(:client)       { create(:client) }

  before do
    create(:practitioner_client, practitioner: practitioner, client: client)
    sign_in_as(practitioner)
  end

  it "shows the client's context" do
    get client_path(client)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(client.display_name)
  end

  it "renders even when the client has no profile row" do
    bare = create(:user, role: "client")
    create(:practitioner_client, practitioner: practitioner, client: bare)

    get client_path(bare)

    expect(response).to have_http_status(:ok)
  end

  # The bare example above passes with an empty client. This one carries the
  # shape the seeds produce -- an assignment, logged sessions, check-ins,
  # injuries and equipment -- because that is what actually failed in the app.
  context "with a full history, the way the seeds build it" do
    let(:program)    { create(:program, practitioner: practitioner) }
    let(:version)    { create(:program_version, program: program) }
    let(:assignment) do
      create(:program_assignment, client: client, practitioner: practitioner,
                                  program_version: version)
    end
    let(:week)       { create(:program_week, program_version: assignment.program_version) }
    let(:day)        { create(:program_day, program_week: week, position: 1) }
    let(:block)      { create(:program_block, program_day: day) }
    let(:slot)       { create(:block_exercise, program_block: block) }

    before do
      profile = client.client_profile
      create(:client_injury_record, client_profile: profile) if defined?(ClientInjury)
      [ [ 3.weeks.ago, 20 ], [ 2.weeks.ago, 22.5 ], [ 1.week.ago, 25 ] ].each do |at, load|
        session = create(:session, program_assignment: assignment, program_day: day,
                                   status: "completed", started_at: at, completed_at: at)
        create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                         load_value: load, load_unit: "lb", reps_completed: 10, completed_at: at)
      end
      create(:check_in, client: client, week_of: 1.week.ago.to_date.beginning_of_week)
      create(:check_in, client: client, week_of: Date.current.beginning_of_week)
    end

    it "renders the whole page" do
      get client_path(client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(slot.exercise.name_es)
      expect(response.body).to include(day.display_name)
      expect(response.body).to include("<svg")
    end

    it "shows the program the client is actually on" do
      get client_path(client)

      expect(response.body).to include(assignment.program.name)
    end

    it "opens the assigned program from the client page" do
      get client_path(client)

      program_link = Nokogiri::HTML(response.body).at_css(
        "a[href='#{program_path(assignment.program)}']"
      )
      expect(program_link).to be_present

      get program_link["href"]

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(assignment.program.name)
    end
  end

  it "refuses a client who is not theirs" do
    stranger = create(:client)

    with_production_error_pages { get client_path(stranger) }

    expect(response).to have_http_status(:not_found)
  end

  it "is closed to clients" do
    sign_in_as(client)

    get client_path(client)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to be_present
  end
end
