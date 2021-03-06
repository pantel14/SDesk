class SolutionsController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!, except: [:show, :knowledge_base, :search]

  add_breadcrumb I18n.t('solutions.knowledge_base.title'), :knowledge_base_path
  add_breadcrumb I18n.t('activerecord.models.solution.other'), :knowledge_base_path, if: :user_signed_in?

  def knowledge_base
    @solution_categories = SolutionCategory.joins(:solution_folders).group('solution_categories.id').order('solution_categories.name')

    render :index if user_signed_in? && !current_user.role?(:requester)
  end

  def search
    add_breadcrumb I18n.t('solutions.search.title')
    @query_text = params[:text]

    @results = Solution.where(%Q[title RLIKE ? OR content RLIKE ? OR tags RLIKE ?], @query_text, @query_text, @query_text)
                   .page(params[:page]).per(10)
  end

  def index
    respond_to do |format|
      format.html
      format.json {render json: SolutionDatatable.new(view_context)}
    end
  end

  def new
    @solution = Solution.new
    render :edit
  end

  def create
    @solution = Solution.new(solution_params)

    if @solution.save
      redirect_to knowledge_base_path, notice: t('.success', value: @solution.title)
    else
      render :edit
    end
  end

  def show
    add_breadcrumb I18n.t('activerecord.models.solution.other')

    @solution = Solution.find(params[:id])
  end

  def edit
    @solution = Solution.find(params[:id])
  end

  def update
    @solution = Solution.find(params[:id])

    if @solution.update_attributes(solution_params)
      redirect_to knowledge_base_path, notice: t('.success', value: @solution.title)
    else
      render :edit
    end
  end

  def destroy
    @solution = Solution.find(params[:id])

    if @solution.destroy
      message = t('.success', value: @solution.title)
      flash.now[:notice] = message
    else
      message = t('.error', value: @solution.title)
      flash.now[:alert] = message
    end

    render 'shared/js/destroy'
  end

  private

  def solution_params
    params.require(:solution).permit(:title, :solution_folder_id, :tags, :content,
                                     file_attachments_attributes:[:id, :_destroy, :file])
  end
end
