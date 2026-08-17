class ApplicationController < ActionController::Base
  # Only allow modern browsers. The client app is a PWA on a phone; the
  # practitioner app is a desktop browser. Neither needs legacy support.
  allow_browser versions: :modern

  before_action :authenticate_user!
  around_action :with_user_locale_and_zone

  private

  # Every request runs in the signed-in user's language and timezone.
  # Cristian and Andres work in Spanish; timestamps are stored UTC and
  # rendered local, so "yesterday's session" means yesterday to them.
  def with_user_locale_and_zone(&block)
    locale = current_user&.locale.presence || I18n.default_locale
    zone   = current_user&.timezone.presence || Time.zone.name

    I18n.with_locale(locale) { Time.use_zone(zone, &block) }
  end
end
