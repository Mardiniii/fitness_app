class EnableExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pgcrypto"  # gen_random_uuid() for offline sync keys
    enable_extension "citext"    # case-insensitive email
    enable_extension "pg_trgm"   # fuzzy exercise matching on plan import
  end
end
