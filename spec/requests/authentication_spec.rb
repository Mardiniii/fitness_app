require "rails_helper"

RSpec.describe "Authentication", type: :request do
  # This suite used to sign in by POSTing straight to user_session_path, which
  # never renders the form -- so it could not see that the form was pointing
  # somewhere else entirely. These examples go through the markup.
  describe "the sign-in form" do
    before { get new_user_session_path }

    it "renders" do
      expect(response).to have_http_status(:ok)
    end

    # Regression: `resources :sessions` (workout sessions) defines a
    # session_path route helper that shadows Devise's session_path(resource)
    # alias. The form posted to /sessions/user -- the show route with "user"
    # as the id -- and sign-in returned a routing error.
    it "posts to Devise, not to the workout sessions route" do
      expect(response.body).to match(/<form[^>]+action="#{Regexp.escape(user_session_path)}"/)
      expect(response.body).not_to include("/sessions/user")
    end

    it "has no nested forms" do
      expect(response.body).to have_no_nested_forms
    end
  end

  describe "signing in through the rendered form" do
    let(:client) { create(:client) }

    it "authenticates and lands on the dashboard" do
      get new_user_session_path
      action = response.body[/<form[^>]+action="([^"]+)"/, 1]

      post action, params: { user: { email: client.email, password: "fitfusion123" } }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(client.display_name)
    end

    # Devise answers a failed sign-in with 422 rather than 401 so Turbo will
    # render the response instead of discarding it.
    it "re-renders the form rather than blowing up" do
      post user_session_path, params: { user: { email: client.email, password: "wrong" } }

      expect(response.status).to eq(422)
      expect(response).not_to be_redirect
      expect(response.body).to include(user_session_path)
    end
  end

  describe "the password reset form" do
    it "posts to Devise rather than a shadowed helper" do
      get new_user_password_path

      expect(response.body).to match(/<form[^>]+action="#{Regexp.escape(user_password_path)}"/)
    end
  end

  # A cheap, general guard: any route helper this app defines that also exists
  # as a Devise alias will silently win inside Devise's own views.
  describe "route helper collisions with Devise" do
    it "documents the ones that collide, so a new one is a deliberate choice" do
      devise_aliases = %w[
        session_path new_session_path destroy_session_path
        password_path new_password_path edit_password_path
        registration_path new_registration_path
        confirmation_path unlock_path
      ]
      app_helpers = Rails.application.routes.named_routes.helper_names.map { |h| h.sub(/_url$/, "_path") }

      colliding = devise_aliases & app_helpers

      # session_path is ours on purpose: /sessions/:id is the workout session.
      # Every Devise view therefore uses the explicit user_* helper.
      expect(colliding).to contain_exactly("session_path")
    end
  end
end
