require "rails_helper"

RSpec.describe "Program assignments", type: :request do
  let(:practitioner) { create(:practitioner) }
  let(:client)       { create(:client) }
  let!(:relationship) do
    create(:practitioner_client, practitioner: practitioner, client: client, status: "active")
  end

  def published_program(template: false)
    program = create(:program, practitioner: practitioner, template: template)
    version = create(:program_version, program: program)
    create(:program_week, program_version: version)
    version.publish!
    program
  end

  before { sign_in_as(practitioner) }

  it "assigns a program to one of the practitioner's clients" do
    program = published_program

    expect { post program_program_assignments_path(program), params: { client_id: client.id } }
      .to change(ProgramAssignment, :count).by(1)

    expect(ProgramAssignment.last.client).to eq(client)
  end

  it "refuses to assign somebody else's client" do
    program = published_program
    stranger = create(:client)

    expect { post program_program_assignments_path(program), params: { client_id: stranger.id } }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "reports rather than raising when nothing is published" do
    program = create(:program, practitioner: practitioner)
    create(:program_version, program: program)

    post program_program_assignments_path(program), params: { client_id: client.id }

    expect(flash[:alert]).to be_present
    expect(ProgramAssignment.count).to eq(0)
  end

  it "renders the assignment section without nested forms" do
    program = published_program(template: true)
    program.assign_to!(client: client)

    get program_path(program)

    expect(response).to have_http_status(:ok)
    expect(response.body).to have_no_nested_forms
  end

  it "removes an assignment" do
    program = published_program
    assignment = program.assign_to!(client: client)

    expect { delete program_assignment_path(assignment) }
      .to change(ProgramAssignment, :count).by(-1)
  end
end
