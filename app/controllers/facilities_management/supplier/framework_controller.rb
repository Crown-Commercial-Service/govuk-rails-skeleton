class FacilitiesManagement::Supplier::FrameworkController < ::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user
  before_action :redirect_if_unrecognised_framework

  protected

  def authorize_user
    authorize! :read, FacilitiesManagement::Supplier
  end

  def redirect_if_unrecognised_framework
    redirect_to facilities_management_unrecognised_framework_path unless FacilitiesManagement::RECOGNISED_FRAMEWORKS.include? params[:framework]
  end
end
