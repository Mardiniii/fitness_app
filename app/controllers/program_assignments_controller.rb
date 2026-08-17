class ProgramAssignmentsController < ApplicationController
  include PractitionerOnly

  before_action :set_program,    only: :create
  before_action :set_assignment, only: %i[update destroy]

  def create
    client = current_user.clients.find(params[:client_id])
    assignment = @program.assign_to!(client: client, starts_on: params[:starts_on].presence || Date.current)

    redirect_to @program, status: :see_other,
                notice: t(".assigned", client: client.display_name,
                          version: assignment.program_version.version_number)
  rescue ActiveRecord::RecordInvalid
    redirect_to @program, alert: t(".not_published"), status: :see_other
  end

  def update
    @assignment.update(status: params[:status])
    redirect_back fallback_location: programs_path, status: :see_other
  end

  def destroy
    program = @assignment.program_version.program
    @assignment.destroy!
    redirect_to program, notice: t(".removed"), status: :see_other
  end

  private

  def set_program
    @program = current_user.authored_programs.kept.find(params[:program_id])
  end

  def set_assignment
    @assignment = ProgramAssignment.where(practitioner: current_user).find(params[:id])
  end
end
