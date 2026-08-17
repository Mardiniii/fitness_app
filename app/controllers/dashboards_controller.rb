class DashboardsController < ApplicationController
  def show
    if current_user.practitioner?
      @clients = current_user.clients.kept.order(:name)
      @programs = current_user.authored_programs.kept.order(updated_at: :desc).limit(5)
    else
      @assignment = current_user.program_assignments.current.order(starts_on: :desc).first
      @next_day = @assignment&.next_program_day
      # A session left mid-workout resumes rather than restarting, so a phone
      # that died at set 4 does not come back to an empty screen.
      @open_session = @assignment&.sessions&.find_by(status: "in_progress")
      @latest_check_in = current_user.check_ins.recent.first
    end
  end
end
