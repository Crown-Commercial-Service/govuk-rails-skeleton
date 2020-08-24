module FacilitiesManagement
  class ProcurementBuildingsController < FacilitiesManagement::FrameworkController
    before_action :set_procurement_building
    before_action :authorize_user
    before_action :set_building_data
    before_action :set_back_path
    before_action :set_service_question, only: %i[edit update]

    def show; end

    def edit; end

    def update
      update_missing_region if params['add_missing_region'].present?
    end

    private

    def building_params
      params.require(:facilities_management_building)
            .permit(:address_region)
    end

    def set_procurement_building
      @procurement_building = ProcurementBuilding.find(params[:id])
    end

    def set_building_data
      @building = @procurement_building.building
    end

    def set_back_path
      @back_link = :back
    end

    def set_service_question
      @service_question = params[:service_question]
    end

    def update_missing_region
      @building.assign_attributes(building_params)
      @building.add_region_code_from_address_region

      if @building.save(context: :all)
        redirect_to facilities_management_procurement_path(@procurement_building.procurement)
      else
        @service_question = 'missing_region'
        render :edit
      end
    end

    protected

    def authorize_user
      authorize! :manage, @procurement_building.procurement
    end
  end
end
