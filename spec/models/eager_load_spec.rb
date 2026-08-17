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

  # Belt and braces: enumerate every enum value on every model and confirm the
  # methods Rails will generate do not already exist on ActiveRecord::Base.
  it "defines no enum whose generated methods collide with ActiveRecord" do
    Rails.application.eager_load!
    reserved = ActiveRecord::Base.instance_methods

    collisions = ApplicationRecord.descendants.flat_map do |model|
      model.defined_enums.flat_map do |attribute, values|
        values.keys.filter_map do |value|
          # Rails generates "value?" and "value!" (plus the prefix, if any)
          candidates = [ :"#{value}?", :"#{value}!" ]
          next if candidates.none? { |m| reserved.include?(m) }
          next if model.instance_method(:"#{value}?").owner != model rescue nil

          "#{model.name}##{attribute} value #{value.inspect}"
        end
      end
    end

    expect(collisions).to be_empty,
      "these enum values generate methods ActiveRecord already defines:\n  " \
      "#{collisions.join("\n  ")}"
  end
end
