# Movement library. Names come from Cristian's plans and are long, descriptive
# and inconsistently accented between weeks:
#   "Liberacion posterior sin soltar punta de pies"
# search_name is the accent-stripped, lowercased form used for fuzzy matching
# on plan import. Kept as a real column so the trigram index needs no custom
# SQL function -- which is what keeps schema.rb usable instead of structure.sql.
class Exercise < ApplicationRecord
  pg_enum :default_measure_kind, %w[reps time distance calories], prefix: true, validate: true

  belongs_to :default_equipment_item, class_name: "EquipmentItem", optional: true
  belongs_to :practitioner, class_name: "User", optional: true   # nil = global library

  has_many :block_exercises, dependent: :restrict_with_error
  has_many :block_exercise_alternatives, dependent: :destroy
  has_many :set_logs, dependent: :restrict_with_error

  before_validation :assign_slug
  before_validation :assign_search_name

  validates :name_es, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :kept,   -> { where(discarded_at: nil) }
  scope :global, -> { where(practitioner_id: nil) }

  # Trigram similarity search, tolerant of accents and word order drift.
  scope :matching, ->(query) {
    normalized = Exercise.normalize(query)
    where("search_name % :q", q: normalized)
      .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array(
        [ "similarity(search_name, ?) DESC", normalized ]
      )))
  }

  def self.normalize(value) = I18n.transliterate(value.to_s).downcase.squish

  def display_name = name_es

  private

  def assign_search_name
    self.search_name = self.class.normalize(name_es)
  end

  def assign_slug
    return if slug.present?

    base = self.class.normalize(name_es).gsub(/[^a-z0-9]+/, "-").delete_prefix("-").delete_suffix("-")
    candidate = base
    suffix = 2
    candidate = "#{base}-#{suffix += 1}" while self.class.where(slug: candidate).where.not(id: id).exists?
    self.slug = candidate
  end
end
