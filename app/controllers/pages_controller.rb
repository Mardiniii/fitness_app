# Public marketing pages. Everything else in this app is behind Devise; this
# is the one controller a logged-out visitor is allowed to reach.
class PagesController < ApplicationController
  # ApplicationController enforces `before_action :authenticate_user!`; the
  # landing page is the front door, so it opts out of exactly that filter and
  # nothing else. The locale/timezone around_action still runs and handles a
  # nil current_user by falling back to the defaults.
  skip_before_action :authenticate_user!, only: :home

  # Its own document: no app chrome, no Tailwind. See layouts/landing.html.erb.
  layout "landing"

  def home
  end
end
