class SetLogsController < ApplicationController
  include ClientOnly

  before_action :set_session

  # Idempotent by natural key (session + block exercise + set + segment), so a
  # retried request after a dropped connection updates rather than duplicating.
  # The unique index backs this up: two replays racing each other cannot both
  # insert, and the loser retries against the row the winner just wrote.
  def create
    block_exercise = BlockExercise
                     .where(program_block: @session.program_day.all_blocks)
                     .find(params[:block_exercise_id])

    attempts = 0
    begin
      log = upsert_log(block_exercise)
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts < 2
      return redirect_to(@session, alert: t(".conflict"), status: :see_other)
    end

    if log.persisted? && log.errors.empty?
      redirect_to session_path(@session, anchor: next_anchor(block_exercise)), status: :see_other
    else
      redirect_to session_path(@session, anchor: "ex-#{block_exercise.id}"),
                  alert: log.errors.full_messages.to_sentence.presence || t(".invalid"),
                  status: :see_other
    end
  end

  private

  def set_session
    @session = owned_sessions.find(params[:session_id])
  end

  # Auto-advance: finishing the last set of an exercise lands the client on the
  # next one. Decided here rather than in JS so it survives the redirect, and
  # so the header counts come back from the server already refreshed.
  def next_anchor(block_exercise)
    return "ex-#{block_exercise.id}" unless fully_logged?(block_exercise)

    ordered = @session.program_day.ordered_block_exercises
    index   = ordered.index { |be| be.id == block_exercise.id }
    following = index && ordered[index + 1]

    following ? "ex-#{following.id}" : "ex-#{block_exercise.id}"
  end

  def fully_logged?(block_exercise)
    prescribed = block_exercise.prescribed_sets.pluck(:set_number, :segment_number)
    return false if prescribed.empty?

    logged = @session.set_logs.where(block_exercise_id: block_exercise.id)
                     .pluck(:set_number, :segment_number)
    (prescribed - logged).empty?
  end

  def upsert_log(block_exercise)
    log = @session.set_logs.find_or_initialize_by(
      block_exercise: block_exercise,
      set_number: params[:set_number],
      segment_number: params[:segment_number].presence || 1
    )

    # Only on create: an existing row keeps the identifier it was written with,
    # so a replay of the same set never rewrites someone else's key.
    log.client_uuid ||= params[:client_uuid].presence

    log.assign_attributes(
      exercise_id: resolved_exercise_id(block_exercise),
      reps_completed: params[:reps_completed].presence,
      duration_seconds: params[:duration_seconds].presence,
      distance_value: params[:distance_value].presence,
      calories: params[:calories].presence,
      load_value: params[:load_value].presence,
      load_unit: params[:load_unit].presence,
      rpe_reported: params[:rpe_reported].presence,
      notes: params[:notes].presence,
      skipped: params[:skipped] == "1",
      completed_at: Time.current
    )

    @session.start!
    log.save
    log
  end

  # A substitution is only accepted if the practitioner actually listed it.
  # Anything else falls back to what was prescribed rather than silently
  # recording a movement nobody sanctioned.
  def resolved_exercise_id(block_exercise)
    requested = params[:exercise_id].presence&.to_i
    return block_exercise.exercise_id if requested.nil?

    block_exercise.acceptable_exercises.map(&:id).include?(requested) ? requested : block_exercise.exercise_id
  end
end
