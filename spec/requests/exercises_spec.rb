require "rails_helper"

RSpec.describe "Exercises", type: :request do
  let(:practitioner) { create(:practitioner) }
  let(:client)       { create(:client) }

  describe "access control" do
    it "redirects a signed-out visitor to sign in" do
      get exercises_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "bounces a client to the dashboard" do
      sign_in_as(client)
      get exercises_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "as a practitioner" do
    before { sign_in_as(practitioner) }

    describe "GET /exercises" do
      it "lists exercises and filters by taxonomy axis" do
        create(:exercise, name_es: "Sentadilla", muscle_region: "tren_inferior")
        create(:exercise, name_es: "Press banca", muscle_region: "tren_superior")

        get exercises_path(region: "tren_superior")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Press banca")
        expect(response.body).not_to include(">Sentadilla<")
      end
    end

    # ---------------------------------------------------------------------
    # REGRESSION: a button_to (its own <form>) was nested inside form_with.
    # The browser discards the inner tag, so its hidden _method=delete field
    # was absorbed by the outer form and pressing "Guardar" issued a DELETE.
    # The exercise was unreferenced, so it was hard-deleted, not archived.
    # ---------------------------------------------------------------------
    describe "PATCH /exercises/:id" do
      let!(:exercise) { create(:exercise, name_es: "Bench press con mancuernas") }

      it "updates the exercise and does NOT destroy it" do
        patch exercise_path(exercise), params: {
          exercise: { reference_url: "https://drive.google.com/file/d/1A2b3C4d5E6f7G8h9I0jK/view" }
        }

        expect(Exercise.find_by(id: exercise.id)).to be_present
        expect(exercise.reload.reference_url).to be_present
        expect(exercise.discarded_at).to be_nil
      end
    end

    describe "the edit page markup" do
      it "has no nested forms" do
        exercise = create(:exercise)
        get edit_exercise_path(exercise)
        expect(response.body).to have_no_nested_forms
      end

      it "has no nested forms when a video is attached" do
        exercise = create(:exercise, reference_url: "https://youtu.be/dQw4w9WgXcQ")
        get edit_exercise_path(exercise)
        expect(response.body).to have_no_nested_forms
      end
    end

    describe "DELETE /exercises/:id" do
      it "hard-deletes an unreferenced exercise" do
        exercise = create(:exercise)
        expect { delete exercise_path(exercise) }.to change(Exercise, :count).by(-1)
      end

      it "archives one that is in use, preserving history" do
        exercise = create(:exercise)
        create(:block_exercise, exercise: exercise)

        expect { delete exercise_path(exercise) }.not_to change(Exercise, :count)
        expect(exercise.reload.discarded_at).to be_present
      end
    end

    describe "taxonomy confirmation" do
      it "confirms a single exercise" do
        exercise = create(:exercise, taxonomy_confirmed: false)
        patch confirm_exercise_path(exercise)
        expect(exercise.reload.taxonomy_confirmed).to be(true)
      end

      it "bulk-confirms only what the current filter selects" do
        create(:exercise, muscle_region: "tren_inferior", taxonomy_confirmed: false)
        untouched = create(:exercise, muscle_region: "tren_superior", taxonomy_confirmed: false)

        patch confirm_all_exercises_path(region: "tren_inferior")

        expect(untouched.reload.taxonomy_confirmed).to be(false)
        expect(Exercise.where(muscle_region: "tren_inferior").pluck(:taxonomy_confirmed)).to all(be(true))
      end
    end
  end
end
