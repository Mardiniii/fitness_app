module PractitionerOnly
  extend ActiveSupport::Concern

  included do
    before_action :require_practitioner!
  end

  private

  def require_practitioner!
    redirect_to root_path, alert: t("errors.practitioners_only") unless current_user.practitioner?
  end
end
