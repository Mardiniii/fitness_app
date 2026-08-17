# Movement library. Names come from Cristian's plans and are long, descriptive
# and inconsistently accented between weeks:
#   "Liberacion posterior sin soltar punta de pies"
# search_name is the accent-stripped, lowercased form used for fuzzy matching
# on plan import. Kept as a real column so the trigram index needs no custom
# SQL function -- which is what keeps schema.rb usable instead of structure.sql.
class Exercise < ApplicationRecord
  pg_enum :default_measure_kind, %w[reps time distance calories], prefix: true, validate: true

  # Cristian's own four axes, from his classification sheet. Spanish values are
  # deliberate -- they are his working vocabulary, not labels to translate.
  pg_enum :muscle_region,      %w[tren_inferior tren_superior full_body], prefix: :region, validate: true
  pg_enum :movement_structure, %w[aislado compuesto],                     prefix: true,    validate: true
  pg_enum :training_quality,   %w[aceleracion fuerza],                    prefix: true,    validate: true
  pg_enum :training_purpose,   %w[movilidad fortaleza],                   prefix: true,    validate: true

  belongs_to :default_equipment_item, class_name: "EquipmentItem", optional: true
  belongs_to :practitioner, class_name: "User", optional: true   # nil = global library

  has_many :block_exercises, dependent: :restrict_with_error
  has_many :block_exercise_alternatives, dependent: :destroy
  has_many :set_logs, dependent: :restrict_with_error

  before_validation :assign_slug
  before_validation :assign_search_name

  validates :name_es, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :kept,      -> { where(discarded_at: nil) }
  scope :global,    -> { where(practitioner_id: nil) }
  # Rows we classified from the PDFs, still awaiting the practitioner's sign-off
  scope :unconfirmed, -> { where(taxonomy_confirmed: false) }

  # Pure trigram similarity -- used by the plan importer, where the input is a
  # whole phrase lifted from a PDF and we want the closest library match.
  scope :matching, ->(query) {
    normalized = Exercise.normalize(query)
    where("search_name % :q", q: normalized)
      .order(Arel.sql(sanitize_sql_array([ "similarity(search_name, ?) DESC", normalized ])))
  }

  # UI search. Trigram alone is too strict for short queries ("sent" would not
  # reach the 0.3 similarity threshold), so substring matching runs alongside it
  # and results are still ranked by similarity.
  scope :search, ->(query) {
    next all if query.blank?

    normalized = Exercise.normalize(query)
    where("search_name ILIKE :like OR search_name % :fuzzy",
          like: "%#{sanitize_sql_like(normalized)}%", fuzzy: normalized)
      .order(Arel.sql(sanitize_sql_array([ "similarity(search_name, ?) DESC", normalized ])))
  }

  scope :filtered_by, ->(region:, structure:, quality:, purpose:, confirmed:) {
    scope = all
    scope = scope.where(muscle_region: region)           if region.present?
    scope = scope.where(movement_structure: structure)   if structure.present?
    scope = scope.where(training_quality: quality)       if quality.present?
    scope = scope.where(training_purpose: purpose)       if purpose.present?
    scope = scope.where(taxonomy_confirmed: confirmed == "true") if confirmed.in?(%w[true false])
    scope
  }

  def self.normalize(value) = I18n.transliterate(value.to_s).downcase.squish

  def display_name = name_es

  # nil when no URL is set, so views can just check presence
  def video = VideoLink.wrap(reference_url)
  def video? = reference_url.present?

  def discarded? = discarded_at.present?

  # Everywhere this exercise is referenced. Being merely an *alternative* on a
  # block counts: removing it would silently change a prescribed substitution.
  def reference_count
    block_exercises.count + set_logs.count + block_exercise_alternatives.count
  end

  # Safe to erase only if nothing points at it. Once a client has logged a set
  # against an exercise, deleting it would rewrite their progression history --
  # which is the one thing this whole app exists to preserve.
  def deletable? = reference_count.zero?

  def restore! = update!(discarded_at: nil)

  private

  def assign_search_name
    self.search_name = self.class.normalize(name_es)
  end

  def assign_slug
    return if slug.present?

    base = self.class.normalize(name_es).gsub(/[^a-z0-9]+/, "-").delete_prefix("-").delete_suffix("-")
    candidate = base
    suffix = 1
    candidate = "#{base}-#{suffix += 1}" while self.class.where(slug: candidate).where.not(id: id).exists?
    self.slug = candidate
  end
end
