# The gym-side screens. A practitioner viewing their own client's session is a
# reasonable future feature, but it is not this: these actions are scoped to
# the signed-in client's own assignments.
module ClientOnly
  extend ActiveSupport::Concern

  private

  def current_assignment
    @current_assignment ||= current_user.program_assignments.current.order(starts_on: :desc).first
  end

  def owned_sessions
    Session.joins(:program_assignment)
           .where(program_assignments: { client_id: current_user.id })
  end
end
