# rubocop:disable Metrics/ModuleLength
module FacilitiesManagement::BuildingsHelper
  def building_rows
    {
      building_name: { row_name: t('facilities_management.buildings.action_partials.show.caption_name'), row_text: @page_data[:model_object].building_name, step: 'building_details' },
      building_description: { row_name: t('facilities_management.buildings.action_partials.show.caption_desc'), row_text: @page_data[:model_object].description, step: 'building_details' },
      address: { row_name: t('facilities_management.buildings.action_partials.show.caption_addr'), row_text: @page_data[:model_object].address_line_1, step: 'building_details' },
      region: { row_name: t('facilities_management.buildings.action_partials.show.caption_region_nuts'), row_text: @page_data[:model_object].address_region, step: 'building_details' },
      gia: { row_name: t('facilities_management.buildings.action_partials.show.caption_gia'), row_text: @page_data[:model_object].gia, step: 'gia' },
      external_area: { row_name: t('facilities_management.buildings.action_partials.show.caption_external_area'), row_text: @page_data[:model_object].external_area, step: 'gia' },
      building_type: { row_name: t('facilities_management.buildings.action_partials.show.caption_type'), row_text: @page_data[:model_object].building_type, step: 'type' },
      security_type: { row_name: t('facilities_management.buildings.action_partials.show.caption_sec'), row_text: @page_data[:model_object].security_type, step: 'security' }
    }
  end

  def address?(building)
    return false if building.blank?

    building.address_town || building.address_line_1 || building.address_postcode || building.address_region
  end

  def address_in_a_line(building)
    [building.address_line_1, building.address_line_2, building.address_town].reject(&:blank?).join(', ') + " #{building.address_postcode}"
  end

  def building_row_text(attribute, building, text)
    case attribute
    when :address
      address_in_a_line(building)
    when :gia, :external_area
      "#{number_with_delimiter(text.to_i, delimiter: ',')} sqm"
    when :building_type
      type_description(building_type_description(text), building, :other_building_type)
    when :security_type
      type_description(text, building, :other_security_type)
    else
      text
    end
  end

  def type_description(text, building, attribute)
    if ['Other', 'other'].include?(text)
      "Other — #{building[attribute].truncate(150)}"
    else
      text
    end
  end

  def edit_link(change_answer, step)
    link_to((change_answer ? t('facilities_management.buildings.show.answer_question_text') : t('facilities_management.buildings.show.change_text')), edit_facilities_management_building_path(params[:framework], @page_data[:model_object].id, step: step), role: 'link', class: 'govuk-link')
  end

  def cant_find_address_link
    add_address_facilities_management_building_path(params[:framework], @page_data[:model_object].id)
  end

  def continuation_params(page_defs, form, step)
    case step
    when 'building_details'
      [page_defs, form, true, false, true]
    when 'security'
      [page_defs, form, false]
    else
      [page_defs, form]
    end
  end

  def open_state_of_building_details
    @open_state_of_building_details ||= should_building_details_be_open?
  end

  def should_building_details_be_open?
    return false if @page_data[:model_object][:building_type].blank?

    if @page_data[:model_object].building_type == 'other' || @page_data[:model_object].errors.key?(:other_building_type) ||
       FacilitiesManagement::Building::BUILDING_TYPES[0..1].map { |bt| bt[:id] }.exclude?(@page_data[:model_object][:building_type])
      true
    else
      false
    end
  end

  def building_type_description(building_type_id)
    building_type = FacilitiesManagement::Building::BUILDING_TYPES.find { |bt| bt[:id] == building_type_id }
    if building_type.present?
      building_type[:title].capitalize
    else
      building_type_id.capitalize
    end
  end

  def building_type_radio_button(form, building_type, disabled)
    tag.div(class: 'govuk-radios__item') do
      capture do
        concat(form.radio_button(:building_type, building_type[:id], class: 'govuk-radios__input', disabled: disabled))
        concat(
          form.label(:building_type, value: building_type[:id], class: 'govuk-label govuk-radios__label govuk-label--s') do
            concat(building_type[:title])
            concat(building_type_caption(building_type))
          end
        )
      end
    end
  end

  def building_type_caption(building_type)
    tag.span(class: 'govuk-caption-m govuk-!-margin-top-1') do
      concat(building_type[:caption])
      if building_type[:standard_building_type]
        concat(tag.hr(class: 'govuk-section-break govuk-!-margin-top-1'))
        concat(govuk_tag_with_text(:grey, t('common.da_eligible')))
      end
    end
  end

  def select_a_region_visible?
    @select_a_region_visible ||= @page_data[:model_object].address_line_1.present? && @page_data[:model_object].address_region.blank?
  end

  def full_region_visible?
    @full_region_visible ||= @page_data[:model_object].address_region.present?
  end
end
# rubocop:enable Metrics/ModuleLength
