require "rails_helper"

RSpec.describe "Model to table mapping" do
  # ClientEquipment inferred client_equipments while the table is
  # client_equipment ("equipment" is uncountable). Nothing queried through it
  # for weeks, so the first symptom was a 500 on the practitioner's client page
  # and a seed run that died half way. A model whose table does not exist is
  # not something to discover from a stack trace.
  it "points every model at a table that exists" do
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.reject(&:abstract_class?)
    expect(models.size).to be >= 20

    broken = models.reject { |model| model.table_exists? }
                   .map { |model| "#{model.name} -> #{model.table_name}" }

    expect(broken).to be_empty, -> { "Models with no table:\n  #{broken.join("\n  ")}" }
  end

  # Every column a model declares an enum for has to actually be an enum column,
  # and every association has to resolve. Cheap to check, and both fail at
  # request time rather than at boot.
  it "resolves every association to a real class and key" do
    Rails.application.eager_load!

    broken = []
    ApplicationRecord.descendants.reject(&:abstract_class?).each do |model|
      model.reflect_on_all_associations.each do |association|
        next if association.polymorphic? || association.options[:through]

        begin
          association.klass
        rescue NameError => e
          broken << "#{model.name}##{association.name}: #{e.message}"
        end
      end
    end

    expect(broken).to be_empty, -> { broken.join("\n  ") }
  end
end
