class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Wires a native PostgreSQL enum column to an ActiveRecord enum.
  #
  # PG enums are string-backed, so the stored value equals the key -- unlike
  # Rails' default array form, which maps to integers and would silently
  # corrupt these columns.
  #
  #   pg_enum :load_kind, %w[none bodyweight external band machine], prefix: :load
  #
  # Prefixes matter: an unprefixed `none` value would override
  # ActiveRecord::Base.none, and `time` / `m` make for terrible scope names.
  def self.pg_enum(name, values, **options)
    enum name, values.to_h { |v| [ v.to_sym, v.to_s ] }, **options
  end
end
