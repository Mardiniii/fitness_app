class SessionsController < ApplicationController
  include ClientOnly

  before_action :set_session, only: %i[show complete]

  # Starting a day. Idempotent: returning to an unfinished session resumes it
  # rather than creating a second one, which matters because a phone in a gym
  # gets backgrounded, locked and reopened constantly.
  def create
    assignment = current_assignment
    return redirect_to(root_path, alert: t(".no_program")) if assignment.nil?

    day = requested_day(assignment) || assignment.next_program_day
    return redirect_to(root_path, alert: t(".no_day")) if day.nil?

    session = assignment.sessions.find_or_create_by!(program_day: day) { |s| s.status = "pending" }
    session.start!

    redirect_to session, status: :see_other
  end

  def show
    @day        = @session.program_day
    @assignment = @session.program_assignment
    # One exercise per screen, in the order the client works through them.
    @exercises = @day.program_blocks
                     .includes(child_blocks: { block_exercises: [ :exercise, :prescribed_sets ] },
                               block_exercises: [ { exercise: :default_equipment_item },
                                                  { prescribed_sets: :equipment_item },
                                                  { block_exercise_alternatives: :exercise } ])
                     .order(:position)
                     .flat_map { |block| ordered_within(block) }

    # Logged sets keyed for O(1) lookup in the view, and the previous session's
    # numbers for the "la vez pasada" panel -- both resolved here so the view
    # does no querying per row.
    @logs = @session.set_logs.index_by { |l| [ l.block_exercise_id, l.set_number, l.segment_number ] }
    @previous = previous_by_exercise

    # Which exercise and which set are open, decided here rather than in JS.
    # ?ex= and ?set= mean the runner works with no JavaScript at all: the nav
    # is real links, and Stimulus only intercepts them to avoid the round trip.
    @open_index = requested_index || @exercises.index { |be| unfinished?(be) } || 0
    @open_set_number = params[:set].presence&.to_i
  end

  def complete
    @session.complete!
    redirect_to @session, notice: t(".done"), status: :see_other
  end

  private

  def set_session
    @session = owned_sessions.find(params[:id])
  end

  # Clamped rather than trusted: ?ex=999 opens the last exercise instead of
  # rendering an empty runner.
  def requested_index
    return nil if params[:ex].blank? || @exercises.empty?

    params[:ex].to_i.clamp(0, @exercises.size - 1)
  end

  def unfinished?(block_exercise)
    block_exercise.prescribed_sets.any? do |ps|
      @logs[[ block_exercise.id, ps.set_number, ps.segment_number ]].nil?
    end
  end

  # Depth-first, so a paired "bloque A + bloque B" yields A's exercises then
  # B's. Mirrors ProgramDay#ordered_block_exercises but reuses the preloaded
  # association tree instead of firing fresh queries per block.
  def ordered_within(block)
    block.block_exercises.to_a + block.child_blocks.flat_map { |child| ordered_within(child) }
  end

  # Scoped to the assignment's own version, so a client cannot start a day that
  # belongs to somebody else's program by guessing an id.
  def requested_day(assignment)
    return nil if params[:program_day_id].blank?

    ProgramDay.where(program_week: assignment.program_version.program_weeks)
              .find_by(id: params[:program_day_id])
  end

  # One query for the whole session: the most recent completed set per exercise,
  # from any earlier session. all_blocks rather than program_blocks, because the
  # latter is scoped to top-level blocks and would skip every exercise nested
  # inside a paired "bloque A + bloque B".
  def previous_by_exercise
    exercise_ids = BlockExercise.where(program_block: @session.program_day.all_blocks)
                                .pluck(:exercise_id)
    return {} if exercise_ids.empty?

    SetLog.done
          .where(exercise_id: exercise_ids)
          .where.not(session_id: @session.id)
          .order(completed_at: :desc)
          .group_by(&:exercise_id)
          .transform_values(&:first)
  end
end
