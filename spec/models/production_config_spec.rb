require "rails_helper"

# The eager-load spec runs in the test environment, so it cannot catch a
# production-only misconfiguration. This one reads the YAML directly.
#
# It exists because two separate boot crashes on Heroku had the same shape:
# cable.yml and cache.yml each named a database that database.yml's production
# entry does not define. Solid Cable and Solid Cache both call connects_to at
# class-definition time, so the failure is at boot, not at first use -- which
# means no request-level test would ever reach it.
RSpec.describe "Production configuration" do
  def load_yaml(path)
    raw = Rails.root.join(path).read
    YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(raw) : YAML.load(raw)
  end

  let(:production_databases) do
    prod = load_yaml("config/database.yml")["production"]
    prod.key?("url") || prod.key?("database") ? [ "primary" ] : prod.keys
  end

  %w[cable cache queue].each do |component|
    it "#{component}.yml names no database production does not define" do
      config = load_yaml("config/#{component}.yml")["production"]
      next if config.blank?

      referenced = [
        config["database"],
        config.dig("connects_to", "database", "writing")
      ].compact.map(&:to_s)

      expect(referenced - production_databases).to be_empty,
        "config/#{component}.yml points at #{(referenced - production_databases).join(", ")}, " \
        "but database.yml production defines only #{production_databases.join(", ")}"
    end
  end

  it "does not schedule recurring work while the queue adapter is :async" do
    recurring = load_yaml("config/recurring.yml")["production"]
    expect(recurring).to be_blank,
      "recurring.yml schedules jobs, but production.rb uses the :async queue adapter"
  end
end
