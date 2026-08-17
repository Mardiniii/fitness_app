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
  # NOTE ON validate:
  #   Rails' `validate: true` generates validates_inclusion_of WITHOUT allow_nil,
  #   so it rejects NULL -- which breaks every nullable enum column we have
  #   (equipment default_load_unit, the four exercise taxonomy axes, load_unit,
  #   distance_unit). NOT NULL is already enforced by PostgreSQL, so the Rails
  #   validation exists only to produce a friendly form error rather than a
  #   PG::NotNullViolation. Allowing nil here is therefore safe on every column
  #   and correct on the nullable ones.
  def self.pg_enum(name, values, validate: true, **options)
    validate = { allow_nil: true } if validate == true
    enum name, values.to_h { |v| [ v.to_sym, v.to_s ] }, validate: validate, **options
  end
end
