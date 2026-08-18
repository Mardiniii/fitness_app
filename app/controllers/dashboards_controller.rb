class DashboardsController < ApplicationController
  def show
    current_user.practitioner? ? practitioner_dashboard : client_dashboard
  end

  private

  def practitioner_dashboard
    clients   = current_user.clients.kept.order(:name)
                            .includes(:client_profile,
                                      program_assignments: { program_version: :program_weeks })
    @roster   = ClientSummary.for(clients)
    @programs = current_user.authored_programs.kept.order(updated_at: :desc).limit(5)
  end

  def client_dashboard
    @assignment = current_user.program_assignments.current.order(starts_on: :desc).first

    if @assignment
      # A session left mid-workout resumes rather than restarting, so a phone
      # that died at set 4 does not come back to an empty screen.
      @open_session = @assignment.sessions.find_by(status: "in_progress")
      @next_day     = @assignment.next_program_day
      @done_count   = @assignment.sessions.where(status: "completed").count
      @day_count    = ProgramDay.where(program_week: @assignment.program_version.program_weeks).count

      # No next day AND something already finished means the program is done --
      # which is a different thing from having no program, and must not offer
      # "Empezar sesión" for a day that does not exist.
      @program_complete = @next_day.nil? && @done_count.positive?
      @last_session = @assignment.sessions.where(status: "completed")
                                 .order(completed_at: :desc).first
    end

    @latest_check_in = current_user.check_ins.recent.first
    @check_in_due    = @latest_check_in.nil? ||
                       @latest_check_in.week_of < Date.current.beginning_of_week
  end
end
