# Shared scoping and the published-version guard for everything that edits
# program content below the day level.
module ProgramScoped
  extend ActiveSupport::Concern

  private

  def owned_days
    ProgramDay.joins(program_week: { program_version: :program })
              .where(programs: { practitioner_id: current_user.id })
  end

  # An assignment pins a version, so a published one is frozen. Enforced here
  # rather than only by hiding buttons.
  def guard_editable!(version)
    return true if version.editable?

    redirect_to version.program, alert: t("programs.locked"), status: :see_other
    false
  end
end
