class ExercisesController < ApplicationController
  include PractitionerOnly

  before_action :set_exercise, only: %i[edit update destroy restore confirm]

  FILTER_KEYS = %i[q region structure quality purpose confirmed discarded].freeze

  def index
    @filters = filter_params
    base = @filters[:discarded] == "true" ? Exercise.where.not(discarded_at: nil) : Exercise.kept
    @exercises = base.includes(:default_equipment_item)
                     .search(@filters[:q])
                     .filtered_by(**@filters.except(:q, :discarded).symbolize_keys)
                     .order(:muscle_region, :name_es)

    # Counts are of the whole library, not the filtered set -- the point of the
    # queue badge is "how much is left overall", which a filtered count hides.
    @pending_count   = Exercise.kept.unconfirmed.count
    @total_count     = Exercise.kept.count
    @discarded_count = Exercise.where.not(discarded_at: nil).count
  end

  def new
    @exercise = Exercise.new(taxonomy_confirmed: true)
  end

  def create
    @exercise = Exercise.new(exercise_params)
    @exercise.practitioner = current_user
    # Anything the practitioner types himself is confirmed by definition.
    @exercise.taxonomy_confirmed = true

    if @exercise.save
      redirect_to exercises_path, notice: t(".created", name: @exercise.name_es)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercises_path, notice: t(".updated", name: @exercise.name_es)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Delete when it is safe to, archive when it is not.
  #
  # An unreferenced exercise is genuinely disposable -- seed noise, a typo, a
  # duplicate spotted during review -- and archiving those would just grow a
  # junk drawer. But once a program prescribes it or a client has logged a set
  # against it, erasing the row would rewrite history, so it gets archived
  # instead and the reason is shown rather than silently swapped.
  def destroy
    name = @exercise.name_es

    if @exercise.deletable?
      @exercise.destroy!
      redirect_to exercises_path, notice: t(".deleted", name: name), status: :see_other
    else
      count = @exercise.reference_count
      @exercise.update!(discarded_at: Time.current)
      redirect_to exercises_path,
                  notice: t(".archived", name: name, count: count), status: :see_other
    end
  end

  def restore
    @exercise.restore!
    redirect_to exercises_path(discarded: "true"),
                notice: t(".restored", name: @exercise.name_es), status: :see_other
  end

  # Cristian signing off on our reading of his taxonomy, one row at a time.
  def confirm
    @exercise.update!(taxonomy_confirmed: true)
    redirect_back fallback_location: exercises_path, status: :see_other
  end

  # Bulk sign-off, scoped to whatever is currently filtered -- so he can confirm
  # "all lower-body compound strength" in one action rather than 40 clicks.
  def confirm_all
    filters = filter_params
    count = Exercise.kept
                    .search(filters[:q])
                    .filtered_by(**filters.except(:q, :discarded).symbolize_keys)
                    .where(taxonomy_confirmed: false)
                    .update_all(taxonomy_confirmed: true, updated_at: Time.current)

    redirect_to exercises_path(filters.compact_blank),
                notice: t(".confirmed", count: count), status: :see_other
  end

  private

  def set_exercise
    # Not scoped to `kept` -- archived rows still need to be editable and
    # restorable, or archiving becomes a black hole.
    @exercise = Exercise.find(params[:id])
  end

  def filter_params
    params.permit(*FILTER_KEYS).to_h.symbolize_keys.tap do |f|
      FILTER_KEYS.each { |k| f[k] = f[k].presence }
    end
  end

  def exercise_params
    params.require(:exercise).permit(
      :name_es, :name_en, :muscle_region, :movement_structure,
      :training_quality, :training_purpose, :default_measure_kind,
      :default_equipment_item_id, :technique_notes, :reference_url,
      :taxonomy_confirmed
    )
  end
end
