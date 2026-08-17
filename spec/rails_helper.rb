require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  # travel_to: session duration and "la vez pasada" ordering are both
  # time-dependent, and asserting them against the wall clock is flaky.
  config.include ActiveSupport::Testing::TimeHelpers
  config.include AuthHelpers, type: :request
  config.include ErrorPageHelpers, type: :request

  # Specs assert Spanish copy, so pin the locale rather than depending on
  # whatever the last example left behind.
  config.before { I18n.locale = :es }
end
