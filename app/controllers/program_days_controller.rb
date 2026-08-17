class ProgramDaysController < ApplicationController
  include PractitionerOnly

  before_action :set_day_for_show, only: :show

  # The block editor: one day at a time, because a day is the unit Cristian
  # actually authors and a whole week on one screen is unreadable.
  def show
    @week    = @day.program_week
    @version = @week.program_version
    @program = @version.program
    @blocks  = @day.program_blocks
                   .includes(:child_blocks, block_exercises: [ :exercise, :prescribed_sets ])
                   .order(:position)
  end

  before_action :set_week, only: :create
  before_action :set_day,  only: %i[update destroy]

  def create
    guard_editable! or return

    position = (@week.program_days.maximum(:position) || 0) + 1
    @week.program_days.create!(position: position)
    redirect_to @week.program_version.program, status: :see_other
  end

  def update
    @week = @day.program_week
    guard_editable! or return

    @day.update(day_params)
    redirect_to @week.program_version.program, status: :see_other
  end

  def destroy
    @week = @day.program_week
    guard_editable! or return

    @day.destroy!
    @week.program_days.order(:position).each_with_index do |day, i|
      day.update_columns(position: i + 1) unless day.position == i + 1
    end
    redirect_to @week.program_version.program, status: :see_other
  end

  private

  def set_week
    @week = ProgramWeek.where(program_version: owned_versions).find(params[:program_week_id])
  end

  def set_day_for_show
    @day = ProgramDay.joins(program_week: { program_version: :program })
                     .where(programs: { practitioner_id: current_user.id })
                     .find(params[:id])
  end

  def set_day
    @day = ProgramDay.joins(program_week: { program_version: :program })
                     .where(programs: { practitioner_id: current_user.id })
                     .find(params[:id])
  end

  def owned_versions
    ProgramVersion.joins(:program).where(programs: { practitioner_id: current_user.id })
  end

  def guard_editable!
    version = @week.program_version
    return true if version.editable?

    redirect_to version.program, alert: t("programs.locked"), status: :see_other
    false
  end

  def day_params = params.require(:program_day).permit(:name, :focus, :description, :reference_url)
end
