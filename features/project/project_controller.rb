require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/*/trigger" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config)
      current_sha = repo.git.log.first.sha

      current_github_provider = self.check_and_get_provider

      # TODO: not the best approach to spawn a thread
      Thread.new do
        FastlaneCI::TestRunnerService.new(
            project: project,
            sha: current_sha,
            provider_credential: current_github_provider
          ).run
      end

      redirect("#{HOME}/#{project_id}")
    end

    get "#{HOME}/*" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
