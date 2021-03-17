module FacilitiesManagement::ProcurementBuildingsServicesHelper
  def volume_question(pbs)
    [] unless pbs.this_service[:context].key? :volume
    pbs.this_service[:context][:volume]&.first
  end

  def service_standard_type
    @building_service.this_service[:context].select { |_, attributes| attributes.first == :service_standard }.keys.first
  end

  def sort_by_lifts_created_at
    parts = @building_service.lifts.partition { |o| o.created_at.nil? }
    parts.last.sort_by(&:created_at) + parts.first
  end

  def link_to_lift_add_row(name, form, association, **args)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render("facilities_management/procurement_buildings_services/#{association.to_s.singularize}", ff: builder)
    end
    link_to(name, '#', class: "add-lifts #{args[:class]}", data: { id: id, fields: fields.gsub('\n', '') })
  end

  def form_model
    params[:service_question] == 'area' ? @building : @building_service
  end

  def page_heading
    params[:service_question] == 'area' ? t('facilities_management.procurement_buildings_services.area.heading') : @building_service.name
  end
end
