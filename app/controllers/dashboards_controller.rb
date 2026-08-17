class DashboardsController < ApplicationController
  def show
    if current_user.practitioner?
      @clients = current_user.clients.kept.order(:name)
      @programs = current_user.authored_programs.kept.order(updated_at: :desc).limit(5)
    else
      @assignment = current_user.program_assignments.current.order(starts_on: :desc).first
      @next_day = @assignment&.next_program_day
      @latest_check_in = current_user.check_ins.recent.first
    end
  end
end
