# C6. Built entirely from set_logs and check_ins -- what happened -- never from
# the prescription, so editing next week's plan cannot rewrite the chart.
class ProgressController < ApplicationController
  include ClientOnly

  def show
    @report = ProgressReport.new(client: current_user)
    @trends = @report.exercise_trends
    @history = @report.session_history
    @check_ins = @report.check_in_trend
  end
end
