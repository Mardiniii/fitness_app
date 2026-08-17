# Deliberately minimal. The generated initializer is ~300 lines of commented-out
# defaults; this keeps only what we actually set.
Devise.setup do |config|
  require "devise/orm/active_record"

  config.mailer_sender = "no-reply@fitfusion.app"

  # users.email is citext, so the DB is already case-insensitive; these keep
  # Devise's in-memory lookups consistent with it.
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  config.skip_session_storage = [ :http_auth ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.expire_all_remember_me_on_sign_out = true
  config.sign_out_via = :delete

  # Required for Devise forms to work under Turbo Drive: without these, a
  # failed sign-in renders 200 and Turbo silently swallows the error.
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
