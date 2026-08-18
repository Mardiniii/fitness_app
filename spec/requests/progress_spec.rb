require "rails_helper"

RSpec.describe "Progress", type: :request do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let(:day)        { create(:program_day, program_week: week, position: 1) }
  let(:block)      { create(:program_block, program_day: day) }
  let(:slot)       { create(:block_exercise, program_block: block) }

  before { sign_in_as(client) }

  it "says so plainly when there is nothing to show yet" do
    get progress_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("progress.empty"))
  end

  it "shows the exercise and its change once two sessions exist" do
    [ [ 3.weeks.ago, 20 ], [ 1.week.ago, 25 ] ].each do |at, load|
      session = create(:session, program_assignment: assignment, program_day: day,
                                 status: "completed", completed_at: at)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       load_value: load, load_unit: "lb", completed_at: at)
    end

    get progress_path

    expect(response.body).to include(slot.exercise.name_es)
    expect(response.body).to include("+25%")
  end

  # The chart is inline SVG on purpose: no CDN, no script, nothing to fail on
  # gym wifi or inside the PWA.
  it "draws the trend as inline SVG with no external asset" do
    [ [ 3.weeks.ago, 20 ], [ 1.week.ago, 25 ] ].each do |at, load|
      session = create(:session, program_assignment: assignment, program_day: day,
                                 status: "completed", completed_at: at)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       load_value: load, completed_at: at)
    end

    get progress_path

    expect(response.body).to include("<svg")
    expect(response.body).to include("<polyline")
    expect(response.body).not_to match(/<script[^>]+src=/)
  end

  it "never shows another client's numbers" do
    session = create(:session, program_assignment: assignment, program_day: day,
                               status: "completed", completed_at: 1.week.ago)
    create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                     load_value: 20, completed_at: 1.week.ago)

    sign_in_as(create(:client))
    get progress_path

    expect(response.body).not_to include(slot.exercise.name_es)
  end
end

RSpec.describe "Progress charts", type: :request do
  let(:client)     { create(:client) }
  let(:assignment) { create(:program_assignment, client: client) }
  let(:week)       { create(:program_week, program_version: assignment.program_version) }
  let(:day)        { create(:program_day, program_week: week, position: 1) }
  let(:block)      { create(:program_block, program_day: day) }
  let(:slot)       { create(:block_exercise, program_block: block) }

  before do
    sign_in_as(client)
    [ [ 3.weeks.ago, 20 ], [ 1.week.ago, 25 ] ].each do |at, load|
      session = create(:session, program_assignment: assignment, program_day: day,
                                 status: "completed", completed_at: at)
      create(:set_log, session: session, block_exercise: slot, exercise: slot.exercise,
                       load_value: load, load_unit: "lb", completed_at: at)
    end
    create(:check_in, client: client, week_of: 2.weeks.ago.to_date.beginning_of_week,
                      bodyweight_kg: 79.6)
    create(:check_in, client: client, week_of: Date.current.beginning_of_week,
                      bodyweight_kg: 76.9)
    get progress_path
  end

  # A chart without numbers is a shape. These are the numbers.
  it "labels the value axis with the real range and its unit" do
    expect(response.body).to include("25 lb")
    expect(response.body).to include("20 lb")
  end

  it "labels the time axis at both ends" do
    first_date = 3.weeks.ago.in_time_zone(client.timezone).to_date
    last_date  = 1.week.ago.in_time_zone(client.timezone).to_date

    expect(response.body).to include(I18n.l(first_date, format: "%d/%m"))
    expect(response.body).to include(I18n.l(last_date, format: "%d/%m"))
  end

  it "labels the check-in axis in kilos" do
    expect(response.body).to include("79.6")
    expect(response.body).to include("76.9")
  end

  # Green means done and orange means now. Neither means "bad" -- so a metric
  # the app cannot judge the direction of draws in ink instead.
  it "colours load by direction but leaves check-in trends neutral" do
    body = response.body
    expect(body).to include("var(--color-done)")
    expect(body).to include("var(--color-ink)")
  end
end
