class FacilitiesManagement::Supplier::FrameworkController < ::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :raise_if_unrecognised_framework

  protected

  def authorize_user
    authorize! :read, FacilitiesManagement::Supplier
  end
end
