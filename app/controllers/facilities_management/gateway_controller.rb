module FacilitiesManagement
  class GatewayController < ApplicationController
    require_permission :none, only: :index

    def index
      redirect_to facilities_management_path if logged_in?
    end
  end
end
