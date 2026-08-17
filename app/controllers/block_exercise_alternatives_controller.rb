# Stated substitutions: "15 remo en trx o progresion de pull up en Smith o barra".
class BlockExerciseAlternativesController < ApplicationController
  include PractitionerOnly
  include ProgramScoped

  def create
    be = owned_block_exercises.find(params[:block_exercise_id])
    guard_editable!(be.program_block.program_day.program_week.program_version) or return

    position = (be.block_exercise_alternatives.maximum(:position) || 0) + 1
    be.block_exercise_alternatives.create(exercise_id: params[:exercise_id], position: position)

    redirect_to edit_block_exercise_path(be), status: :see_other
  end

  def destroy
    alt = BlockExerciseAlternative.where(block_exercise: owned_block_exercises).find(params[:id])
    guard_editable!(alt.block_exercise.program_block.program_day.program_week.program_version) or return

    be = alt.block_exercise
    alt.destroy!
    redirect_to edit_block_exercise_path(be), status: :see_other
  end

  private

  def owned_block_exercises
    BlockExercise.joins(:program_block)
                 .where(program_blocks: { program_day_id: owned_days.select(:id) })
  end
end
