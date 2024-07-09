class HomeController < ApplicationController
  before_action :authenticate_user!, :validate_service, except: %i[healthcheck index]

  def index
    redirect_to ccs_homepage_url, allow_other_host: true
  end

  def healthcheck
    render json: { status: :ok, git_commit: ENV.fetch('GIT_COMMIT', '') }
  end
end
