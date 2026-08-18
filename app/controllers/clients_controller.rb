# P3. The practitioner's view of one client: the same progress the client sees,
# plus the context Cristian needs before writing next week.
class ClientsController < ApplicationController
  include PractitionerOnly

  def show
    # Scoped through the relationship, so a practitioner can only open a client
    # who is actually theirs.
    @client = current_user.clients.kept.find(params[:id])

    @assignment = @client.program_assignments.current.order(starts_on: :desc).first
    @sessions   = Session.joins(:program_assignment)
                         .where(program_assignments: { client_id: @client.id })
                         .includes(:program_day)
                         .order(Arel.sql("COALESCE(sessions.completed_at, sessions.started_at) DESC"))
                         .limit(10)

    @report    = ProgressReport.new(client: @client)
    @trends    = @report.exercise_trends
    @history   = @report.session_history
    @check_ins = @report.check_in_trend
    # Injuries and equipment hang off the profile, not the user, and a client
    # without a profile row must not blow up the practitioner's page.
    @profile   = @client.client_profile
    @injuries  = @profile ? @profile.client_injuries.active.order(:name) : []
    @equipment = @profile ? @profile.equipment_items.order(:name_es) : []
  end
end
