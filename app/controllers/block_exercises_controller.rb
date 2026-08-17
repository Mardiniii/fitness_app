class BlockExercisesController < ApplicationController
  include PractitionerOnly
  include ProgramScoped

  before_action :set_block,          only: :create
  before_action :set_block_exercise, only: %i[update destroy move]

  def create
    guard_editable!(version_for(@block)) or return

    exercise = Exercise.kept.find(params[:exercise_id])
    position = (@block.block_exercises.maximum(:position) || 0) + 1

    be = @block.block_exercises.create!(exercise: exercise, position: position,
                                        technique_notes: exercise.technique_notes)
    # Seed one set from the exercise's default so the row is never empty.
    be.prescribed_sets.create!(
      set_number: 1,
      measure_kind: exercise.default_measure_kind,
      reps_min: (exercise.default_measure_kind == "reps" ? 10 : nil),
      work_seconds: (exercise.default_measure_kind == "time" ? 30 : nil),
      distance_value: (exercise.default_measure_kind == "distance" ? 100 : nil),
      calories: (exercise.default_measure_kind == "calories" ? 10 : nil),
      load_kind: exercise.default_equipment_item ? "external" : "bodyweight"
    )

    redirect_to program_day_path(@block.program_day), status: :see_other
  end

  def update
    guard_editable!(version_for(@block_exercise.program_block)) or return

    @block_exercise.update(block_exercise_params)
    redirect_to program_day_path(@block_exercise.program_block.program_day), status: :see_other
  end

  def destroy
    guard_editable!(version_for(@block_exercise.program_block)) or return

    block = @block_exercise.program_block
    @block_exercise.destroy!
    block.block_exercises.order(:position).each_with_index do |be, i|
      be.update_columns(position: i + 1) unless be.position == i + 1
    end
    redirect_to program_day_path(block.program_day), status: :see_other
  end

  def move
    guard_editable!(version_for(@block_exercise.program_block)) or return

    offset = params[:direction] == "up" ? -1 : 1
    swap_with = @block_exercise.program_block.block_exercises
                               .find_by(position: @block_exercise.position + offset)

    if swap_with
      ProgramBlock.transaction do
        mine, theirs = @block_exercise.position, swap_with.position
        swap_with.update_columns(position: 0)
        @block_exercise.update_columns(position: theirs)
        swap_with.update_columns(position: mine)
      end
    end

    redirect_to program_day_path(@block_exercise.program_block.program_day), status: :see_other
  end

  private

  def set_block = @block = ProgramBlock.where(program_day: owned_days).find(params[:program_block_id])

  def set_block_exercise
    @block_exercise = BlockExercise.joins(:program_block)
                                   .where(program_blocks: { program_day_id: owned_days.select(:id) })
                                   .find(params[:id])
  end

  def version_for(block) = block.program_day.program_week.program_version

  def block_exercise_params
    params.require(:block_exercise).permit(:per_side, :technique_notes)
  end
end
