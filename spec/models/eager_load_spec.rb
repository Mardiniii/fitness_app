require "rails_helper"

# Production eager-loads every class at boot; development and test lazy-load.
# That gap let PlanImport's `committed` enum -- which generates committed!, an
# existing ActiveRecord method -- reach production and crash the dyno, because
# no spec had ever referenced the class.
#
# This makes the whole app load in CI, so a boot-time failure surfaces here
# rather than in a Heroku log.
RSpec.describe "Application boot" do
  it "eager loads every class without raising" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end

  # Enum/ActiveRecord collisions are already caught above: Rails raises at
  # class-definition time, and eager loading is what triggers it. A separate
  # audit only reproduced that check badly -- it compared the raw enum value
  # against ActiveRecord's methods while ignoring the prefix, so a correctly
  # prefixed value like PlanImport's "committed" (which generates
  # status_committed!) was reported as a collision that does not exist.
  #
  # What is worth asserting instead is that the eager load above is not
  # vacuous. If it silently loaded nothing, it would pass while guarding
  # nothing at all.
  it "actually loads the application's models" do
    Rails.application.eager_load!

    expect(ApplicationRecord.descendants.size).to be >= 20
    expect(ApplicationRecord.descendants.map(&:name)).to include("PlanImport", "PrescribedSet")
  end
end
