class CrownMarketplace::FrameworkController < ::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  protected

  def authorize_user
    authorize! :manage, AllowedEmailDomain
  end
end
