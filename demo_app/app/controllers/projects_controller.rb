class ProjectsController < Salvia::Controller
  def index
    @projects = Project.all.order(created_at: :desc)
    render "projects/index"
  end
end
