class ProgramVersionsController < ApplicationController
  include PractitionerOnly

  before_action :set_version

  def publish
    @version.publish!
    redirect_to @version.program, notice: t(".published", n: @version.version_number), status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to @version.program, alert: t(".empty"), status: :see_other
  end

  # Fork a published version into a new draft, leaving assigned clients on the
  # version they started.
  def fork
    draft = @version.duplicate_as_draft!
    redirect_to @version.program, notice: t(".forked", n: draft.version_number), status: :see_other
  end

  private

  def set_version
    @version = ProgramVersion.joins(:program)
                             .where(programs: { practitioner_id: current_user.id })
                             .find(params[:id])
  end
end
