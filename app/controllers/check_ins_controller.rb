# C5. A direct port of the log table at the back of Cristian's plan: four
# fields, under thirty seconds, once a week.
class CheckInsController < ApplicationController
  include ClientOnly

  before_action :set_check_in, only: %i[edit update destroy]

  def index
    @check_ins = current_user.check_ins.recent.limit(26)
  end

  def new
    # One row per week is the rule the unique index enforces, so opening "new"
    # during a week already logged edits that week rather than failing on save.
    existing = current_user.check_ins.find_by(week_of: Date.current.beginning_of_week)
    return redirect_to edit_check_in_path(existing) if existing

    @check_in = current_user.check_ins.new(
      week_of: Date.current.beginning_of_week,
      program_assignment: current_assignment
    )
  end

  def create
    @check_in = current_user.check_ins.new(check_in_params)
    @check_in.program_assignment ||= current_assignment

    if @check_in.save
      redirect_to check_ins_path, notice: t(".saved"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @check_in.update(check_in_params)
      redirect_to check_ins_path, notice: t(".saved"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @check_in.destroy!
    redirect_to check_ins_path, notice: t(".removed"), status: :see_other
  end

  private

  # Scoped to the signed-in client, so a guessed id is a 404 rather than
  # somebody else's bodyweight.
  def set_check_in
    @check_in = current_user.check_ins.find(params[:id])
  end

  def check_in_params
    params.require(:check_in)
          .permit(:week_of, :bodyweight_kg, :feeling, :sleep_hours_avg, :notes)
  end
end
