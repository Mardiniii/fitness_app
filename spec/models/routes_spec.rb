require "rails_helper"

RSpec.describe "Routes" do
  include Rails.application.routes.url_helpers
  # `resource :progress` silently routed to a ProgressesController that never
  # existed -- Rails pluralizes a singleton resource to find its controller,
  # and "progress".pluralize is "progresses". Nothing failed until a human
  # clicked the link, because a route pointing at a missing controller is only
  # an error at request time.
  it "points every route at a controller and action that exist" do
    broken = []

    Rails.application.routes.routes.each do |route|
      controller = route.defaults[:controller]
      action     = route.defaults[:action]
      next if controller.blank? || action.blank?

      begin
        klass = "#{controller}_controller".camelize.constantize
      rescue NameError
        broken << "#{controller}##{action} — no #{controller.camelize}Controller"
        next
      end

      unless klass.action_methods.include?(action) || klass.method_defined?(action)
        broken << "#{controller}##{action} — #{klass} has no ##{action}"
      end
    end

    expect(broken).to be_empty, -> { "Unreachable routes:\n  #{broken.join("\n  ")}" }
  end

  it "names the singleton progress route the way the views call it" do
    expect(progress_path).to eq("/progress")
    expect(Rails.application.routes.recognize_path("/progress", method: :get))
      .to include(controller: "progress", action: "show")
  end
end
