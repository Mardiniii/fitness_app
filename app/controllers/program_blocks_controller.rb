class ProgramBlocksController < ApplicationController
  include PractitionerOnly
  include ProgramScoped

  before_action :set_day,   only: :create
  before_action :set_block, only: %i[update destroy duplicate add_child]

  def create
    guard_editable!(@day.program_week.program_version) or return

    position = (@day.program_blocks.maximum(:position) || 0) + 1
    @day.program_blocks.create!(position: position, name: "Bloque #{position}",
                                execution_mode: "straight_sets", round_count: 3)
    redirect_to program_day_path(@day), status: :see_other
  end

  def update
    guard_editable!(version_for(@block)) or return

    @block.update(block_params)
    redirect_to program_day_path(@block.program_day), status: :see_other
  end

  def destroy
    guard_editable!(version_for(@block)) or return

    day = @block.program_day
    @block.destroy!
    resequence!(day)
    redirect_to program_day_path(day), status: :see_other
  end

  def duplicate
    guard_editable!(version_for(@block)) or return

    copy = @block.copy_into!(day: @block.program_day)
    copy.update!(position: (@block.program_day.program_blocks.maximum(:position) || 0) + 1)
    redirect_to program_day_path(@block.program_day), status: :see_other
  end

  # A paired block ("1 serie = bloque A + bloque B") holds child blocks rather
  # than exercises of its own.
  def add_child
    guard_editable!(version_for(@block)) or return

    position = (@block.child_blocks.maximum(:position) || 0) + 1
    ProgramBlock.create!(
      program_day: @block.program_day, parent_block: @block,
      position: position, name: "Bloque #{("A".ord + position - 1).chr}",
      execution_mode: "circuit", round_count: @block.round_count
    )
    redirect_to program_day_path(@block.program_day), status: :see_other
  end

  private

  def set_day   = @day = owned_days.find(params[:program_day_id])
  def set_block = @block = ProgramBlock.where(program_day: owned_days).find(params[:id])

  def version_for(block) = block.program_day.program_week.program_version

  def resequence!(day)
    day.program_blocks.order(:position).each_with_index do |block, i|
      block.update_columns(position: i + 1) unless block.position == i + 1
    end
  end

  def block_params
    params.require(:program_block).permit(
      :name, :focus, :execution_mode, :round_count,
      :work_seconds, :rest_seconds, :rest_between_rounds_seconds, :notes
    )
  end
end
