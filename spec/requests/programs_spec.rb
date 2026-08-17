require "rails_helper"

RSpec.describe "Programs", type: :request do
  let(:practitioner) { create(:practitioner) }
  let(:other)        { create(:practitioner) }

  describe "access control" do
    it "redirects a signed-out visitor" do
      get programs_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "bounces a client" do
      sign_in_as(create(:client))
      get programs_path
      expect(response).to redirect_to(root_path)
    end

    # show_exceptions is :rescuable in the test env, so a scoped `find` surfaces
    # as a 404 rather than a raised exception. 404 is also the right answer on
    # its own merits: it does not confirm that the record exists.
    it "hides another practitioner's program" do
      sign_in_as(practitioner)
      theirs = create(:program, practitioner: other, name: "Plan ajeno")

      get program_path(theirs)

      expect(response).to have_http_status(:not_found)
    end

    it "leaks nothing about it in the error page production would serve" do
      sign_in_as(practitioner)
      theirs = create(:program, practitioner: other, name: "Plan ajeno")

      with_production_error_pages { get program_path(theirs) }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Plan ajeno")
    end

    it "refuses to mutate another practitioner's program" do
      sign_in_as(practitioner)
      theirs = create(:program, practitioner: other, name: "Plan ajeno")

      patch program_path(theirs), params: { program: { name: "Secuestrado" } }

      expect(response).to have_http_status(:not_found)
      expect(theirs.reload.name).to eq("Plan ajeno")
    end
  end

  context "as a practitioner" do
    before { sign_in_as(practitioner) }

    it "creates a program and opens a draft immediately" do
      expect { post programs_path, params: { program: { name: "Hipertrofia" } } }
        .to change(Program, :count).by(1)

      program = Program.last
      expect(program.draft_version).to be_present
      expect(response).to redirect_to(program)
    end

    describe "the editor markup" do
      it "has no nested forms with weeks, days and a session video" do
        program = create(:program, practitioner: practitioner)
        version = create(:program_version, program: program)
        week    = create(:program_week, program_version: version)
        create(:program_day, program_week: week,
               reference_url: "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view")

        get program_path(program)

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_no_nested_forms
      end
    end

    describe "editing a published version" do
      let(:program) { create(:program, practitioner: practitioner) }
      let(:version) { create(:program_version, program: program, status: "published") }
      let(:week)    { create(:program_week, program_version: version) }

      # An assignment pins a version. Silently changing it under a client
      # mid-week is the one thing this must never allow.
      it "refuses to add a week" do
        expect { post program_version_program_weeks_path(version) }
          .not_to change(ProgramWeek, :count)
        expect(flash[:alert]).to be_present
      end

      it "refuses to delete a week" do
        week
        expect { delete program_week_path(week) }.not_to change(ProgramWeek, :count)
      end

      it "refuses to duplicate a week" do
        week
        expect { post duplicate_program_week_path(week) }.not_to change(ProgramWeek, :count)
      end
    end

    describe "publishing" do
      it "refuses an empty version and reports why" do
        program = create(:program, practitioner: practitioner)
        version = create(:program_version, program: program)

        patch publish_program_version_path(version)

        expect(version.reload).to be_draft
        expect(flash[:alert]).to be_present
      end

      it "publishes a version that has weeks" do
        program = create(:program, practitioner: practitioner)
        version = create(:program_version, program: program)
        create(:program_week, program_version: version)

        patch publish_program_version_path(version)

        expect(version.reload.status).to eq("published")
      end
    end

    it "stores a session video on a day" do
      program = create(:program, practitioner: practitioner)
      version = create(:program_version, program: program)
      week    = create(:program_week, program_version: version)
      day     = create(:program_day, program_week: week)
      url     = "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view"

      patch program_day_path(day), params: { program_day: { reference_url: url } }

      expect(day.reload.reference_url).to eq(url)
      expect(day.video.provider).to eq(:drive)
    end
  end
end
