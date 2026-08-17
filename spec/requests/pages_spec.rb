require "rails_helper"

RSpec.describe "Public landing page", type: :request do
  describe "GET /" do
    it "serves the landing page to a signed-out visitor" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FitFusion")
      expect(response.body).to include(new_user_session_path)
    end

    it "ships Spanish in the markup, so no-JS visitors get a complete page" do
      get root_path

      expect(response.body).to include('<html lang="es"')
    end

    # The landing page is its own design expression. If it ever inherits the
    # app layout, the FIT/FUSION nav and Tailwind's preflight come with it.
    it "does not render the authenticated app chrome" do
      get root_path

      expect(response.body).not_to include("tailwind")
      expect(response.body).not_to include(destroy_user_session_path)
    end

    it "still sends a signed-in client to their dashboard" do
      client = create(:client)
      sign_in_as(client)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.display_name)
    end
  end

  describe "the rest of the app" do
    it "remains behind authentication" do
      get exercises_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
