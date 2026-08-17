class ProgramsController < ApplicationController
  include PractitionerOnly

  before_action :set_program, only: %i[show edit update destroy open_draft]

  def index
    @programs = current_user.authored_programs.kept
                            .includes(:program_versions).order(updated_at: :desc)
  end

  def show
    # The editable draft, if one is open. Published content is frozen because
    # assignments pin a version.
    @draft     = @program.draft_version
    @published = @program.published_version
    @version   = @draft || @published
    @weeks     = @version ? @version.program_weeks.includes(:program_days).order(:position) : []
  end

  def new
    @program = current_user.authored_programs.build
  end

  def create
    @program = current_user.authored_programs.build(program_params)

    if @program.save
      @program.open_draft!
      redirect_to @program, notice: t(".created", name: @program.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @program.update(program_params)
      redirect_to @program, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @program.update!(discarded_at: Time.current)
    redirect_to programs_path, notice: t(".discarded", name: @program.name), status: :see_other
  end

  # Opens an editable draft, copying the published version when there is one.
  def open_draft
    @program.open_draft!
    redirect_to @program, notice: t(".draft_opened"), status: :see_other
  end

  private

  def set_program
    @program = current_user.authored_programs.kept.find(params[:id])
  end

  def program_params
    params.require(:program).permit(:name, :goal, :description)
  end
end
