module ErrorPageHelpers
  # In test, consider_all_requests_local is true, so Rails renders the detailed
  # debug page for a rescued exception. That page embeds source extracts of
  # backtrace frames -- including the spec file itself -- which makes any
  # "body should not leak X" assertion match its own source and pass or fail
  # for the wrong reason.
  #
  # This renders the static public/404.html that production actually serves,
  # so the assertion tests real behaviour.
  def with_production_error_pages
    key = "action_dispatch.show_detailed_exceptions"
    original = Rails.application.env_config[key]
    Rails.application.env_config[key] = false
    yield
  ensure
    Rails.application.env_config[key] = original
  end
end

module AuthHelpers
  # Devise's sign_in helper needs Warden; going through the real form keeps the
  # specs honest about the actual auth path.
  def sign_in_as(user, password: "fitfusion123")
    post user_session_path, params: {
      user: { email: user.email, password: password }
    }
    follow_redirect! if response.redirect?
    user
  end
end
