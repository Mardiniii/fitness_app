class ProgramWeeksController < ApplicationController
  include PractitionerOnly

  before_action :set_version, only: :create
  before_action :set_week,    only: %i[update destroy duplicate]

  def create
    guard_editable!(@version) or return

    position = (@version.program_weeks.maximum(:position) || 0) + 1
    @version.program_weeks.create!(position: position)
    redirect_to @version.program, status: :see_other
  end

  def update
    guard_editable!(@week.program_version) or return

    @week.update(week_params)
    redirect_to @week.program_version.program, status: :see_other
  end

  def destroy
    guard_editable!(@week.program_version) or return

    @week.destroy!
    resequence!(@week.program_version)
    redirect_to @week.program_version.program, status: :see_other
  end

  def duplicate
    guard_editable!(@week.program_version) or return

    copy = @week.duplicate!
    redirect_to @week.program_version.program,
                notice: t(".duplicated", from: @week.display_name, to: copy.display_name),
                status: :see_other
  end

  private

  def set_version
    @version = owned_versions.find(params[:program_version_id])
  end

  def set_week
    @week = ProgramWeek.where(program_version: owned_versions).find(params[:id])
  end

  def owned_versions
    ProgramVersion.joins(:program).where(programs: { practitioner_id: current_user.id })
  end

  # Published versions are frozen: an assignment pins one, so editing it would
  # silently change a plan a client is part-way through.
  def guard_editable!(version)
    return true if version.editable?

    redirect_to version.program, alert: t("programs.locked"), status: :see_other
    false
  end

  def resequence!(version)
    version.program_weeks.order(:position).each_with_index do |week, i|
      week.update_columns(position: i + 1) unless week.position == i + 1
    end
  end

  def week_params = params.require(:program_week).permit(:name, :focus)
end
