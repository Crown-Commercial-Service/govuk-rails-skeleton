# rubocop:disable Metrics/ModuleLength
module ApplicationHelper
  include LayoutHelper
  include GovUKHelper
  include HeaderNavigationLinksHelper

  ADMIN_CONTROLLERS = ['supply_teachers/admin', 'management_consultancy/admin', 'legal_services/admin'].freeze
  PLATFORM_LANDINGPAGES = ['', 'legal_services/home', 'supply_teachers/home', 'management_consultancy/home'].freeze
  FACILITIES_MANAGEMENT_LANDINGPAGES = ['facilities_management/home'].freeze

  def miles_to_metres(miles)
    DistanceConverter.miles_to_metres(miles)
  end

  def metres_to_miles(metres)
    DistanceConverter.metres_to_miles(metres)
  end

  def feedback_email_link
    link_to(t('common.feedback'), Marketplace.fm_survey_link, target: '_blank', rel: 'noopener', class: 'govuk-link')
  end

  def support_email_link(label)
    govuk_email_link(Marketplace.support_email_address, label, css_class: 'govuk-link ga-support-mailto')
  end

  def footer_email_link(label)
    mail_to(Marketplace.support_email_address, Marketplace.support_email_address, class: 'govuk-link ga-support-mailto', 'aria-label': label)
  end

  def dfe_account_request_url
    'https://ccsheretohelp.uk/contact/?type=ST18/19'
  end

  def support_telephone_number
    Marketplace.support_telephone_number
  end

  def govuk_email_link(email_address, aria_label, css_class: 'govuk-link')
    mail_to(email_address, t('layouts.application.feedback'), class: css_class, 'aria-label': aria_label)
  end

  # rubocop:disable Metrics/ParameterLists
  def govuk_form_field(model_object, attribute, form_object_name, label_text, readable_property_name, top_level_data_options)
    css_classes = %w[govuk-!-margin-top-3]
    form_group_css = ['govuk-form-group']
    form_group_css += ['govuk-form-group--error'] if model_object.errors[attribute].any?
    label_for_id = form_object_name
    id_for_label = "#{form_object_name}_#{attribute}-info"
    label_for_id += "_#{attribute}" if form_object_name.exclude?(attribute.to_s)

    tag.div(class: css_classes, data: { propertyname: readable_property_name }) do
      tag.div(class: form_group_css, data: top_level_data_options) do
        concat display_label(attribute, label_text, label_for_id, id_for_label) if label_text.present?
        concat display_potential_errors(model_object, attribute, "#{form_object_name}_#{attribute}")
        yield
      end
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def display_label(_attribute, text, form_object_name, _id_for_label)
    tag.label(text, class: 'govuk-label', for: form_object_name)
  end

  def govuk_form_group_with_optional_error(journey, *attributes, &block)
    attributes_with_errors = attributes.select { |a| journey.errors[a].any? }

    css_classes = ['govuk-form-group']
    css_classes += ['govuk-form-group--error'] if attributes_with_errors.any?

    tag.div(class: css_classes, &block)
  end

  def govuk_fieldset_with_optional_error(journey, *attributes, &block)
    attributes_with_errors = attributes.select { |a| journey.errors[a].any? }

    options = { class: 'govuk-fieldset' }
    options['aria-describedby'] = attributes_with_errors.map { |a| error_id(a) } if attributes_with_errors.any?

    tag.fieldset(options, &block)
  end

  def list_potential_errors(model_object, attribute, form_object_name, error_lookup = nil, error_position = nil)
    collection = validation_messages(model_object.class.name.underscore.downcase.to_sym, attribute)

    collection.each do |key, val|
      concat(govuk_validation_error({ model_object: model_object, attribute: attribute, error_type: key, text: val, form_object_name: form_object_name }, error_lookup, error_position))
    end
  end

  def property_name(section_name, attributes)
    return "#{section_name}_#{attributes.is_a?(Array) ? attributes.last : attributes}" unless section_name.nil?

    (attributes.is_a?(Array) ? attributes.last : attributes).to_s
  end

  def display_potential_errors(model_object, attributes, form_object_name, section_name = nil)
    collection = validation_messages(model_object.class.name.underscore.downcase.to_sym, attributes)
    return if collection.empty?

    tag.div(class: 'error-collection potenital-error', property_name: property_name(section_name, attributes)) do
      multiple_validation_errors(model_object, attributes, form_object_name, collection)
    end
  end

  def model_attribute_has_error(model_object, *attributes)
    result = false
    attributes.any? { |a| result |= model_object.errors[a]&.any? }
  end

  def model_has_error?(model_object, error_type, *attributes)
    attributes.any? { |a| (model_object&.errors&.details&.dig(a, 0)&.fetch(:error, nil)) == error_type }
  end

  def display_errors(journey, *attributes)
    safe_join(attributes.map { |a| display_error(journey, a) })
  end

  def display_error(journey, attribute, margin = true, id_prefix = '')
    error = journey.errors[attribute].first
    return if error.blank?

    tag.span(id: "#{id_prefix}#{error_id(attribute)}", class: "govuk-error-message #{'govuk-!-margin-top-3' if margin}") do
      error.to_s
    end
  end

  ERROR_TYPES = {
    too_long: 'maxlength',
    too_short: 'minlength',
    blank: 'required',
    inclusion: 'required',
    after: 'max',
    greater_than: 'min',
    greater_than_or_equal_to: 'min',
    before: 'min',
    less_than: 'max',
    less_than_or_equal_to: 'max',
    not_a_date: 'pattern',
    not_a_number: 'number',
    not_an_integer: 'number'
  }.freeze

  def get_client_side_error_type_from_errors(errors, attribute)
    return ERROR_TYPES[errors.details[attribute].first[:error]] if ERROR_TYPES.key?(errors.details[attribute].try(:first)[:error])

    errors.details[attribute].first[:error].to_sym unless ERROR_TYPES.key?(errors.details[attribute].first[:error])
  end

  def get_client_side_error_type_from_model(model, attribute)
    return ERROR_TYPES[model.errors.details[attribute].first[:error]] if ERROR_TYPES.key?(model.errors.details[attribute].first[:error])

    model.errors.details[attribute].first[:error].to_sym unless ERROR_TYPES.key?(model.errors.details[attribute].first[:error])
  end

  def display_error_label(model, attribute, label_text, target)
    error = model.errors[attribute].first
    return if error.blank?

    tag.label(data: { validation: get_client_side_error_type_from_model(model, attribute).to_s }, for: target, id: error_id(attribute), class: 'govuk-error-message') do
      "#{label_text} #{error}"
    end
  end

  def display_error_no_attr(object, attribute)
    error = object.errors[attribute].first
    return if error.blank?

    tag.span(id: error_id(attribute.to_s), class: 'govuk-error-message govuk-!-margin-top-3') do
      error.to_s
    end
  end

  def display_error_nested_models(object, attribute)
    error = object.errors[attribute].first
    return if error.blank?

    tag.span(id: error_id(object.id), class: 'govuk-error-message govuk-!-margin-top-3') do
      error.to_s
    end
  end

  def css_classes_for_input(journey, attribute, extra_classes = [])
    error = journey.errors[attribute].first

    css_classes = ['govuk-input'] + extra_classes
    css_classes += ['govuk-input--error'] if error.present?
    css_classes
  end

  def error_id(attribute)
    "#{attribute}-error"
  end

  def page_title
    title = %i[page_title_prefix page_title page_section].map do |title_bit|
      content_for(title_bit)
    end
    title += [t('layouts.application.title')]
    title.reject(&:blank?).map(&:strip).join(': ')
  end

  def add_optional_error_prefix_to_page_title(errors)
    content_for(:page_title_prefix) { t('layouts.application.error_prefix') } unless errors.empty?
  end

  def hidden_fields_for_previous_steps_and_responses(journey)
    html = ActiveSupport::SafeBuffer.new

    journey.previous_questions_and_answers.each do |(key, value)|
      if value.is_a? Array
        value.each do |v|
          html += hidden_field_tag("#{key}[]", v, id: nil)
        end
      else
        html += hidden_field_tag(key, value)
      end
    end
    html
  end

  def service_header_banner
    if params[:service]
      render partial: "#{params[:service]}/header-banner"
    else
      render partial: 'layouts/header-banner'
    end
  end

  def landing_or_admin_page
    (PLATFORM_LANDINGPAGES.include?(controller.class.controller_path) && controller.action_name == 'index') || controller.action_name == 'landing_page' || ADMIN_CONTROLLERS.include?(controller.class.module_parent_name.try(:underscore))
  end

  def fm_landing_page
    (FACILITIES_MANAGEMENT_LANDINGPAGES.include?(controller.class.controller_path) && controller.action_name == 'index')
  end

  def fm_buyer_landing_page
    request.path_info.include? 'buyer-account'
  end

  def fm_activate_account_landing_page
    controller.controller_name == 'users' && controller.action_name == 'confirm_new'
  end

  def fm_supplier_landing_page
    request.path_info.include? 'supplier'
  end

  def fm_supplier_login_page
    controller.controller_name == 'sessions' && controller.action_name == 'new'
  end

  def fm_back_to_start_page
    [FacilitiesManagement::BuyerAccountController, FacilitiesManagement::SessionsController, FacilitiesManagement::RegistrationsController, FacilitiesManagement::PasswordsController].include? controller.class
  end

  def passwords_page
    controller.controller_name == 'passwords'
  end

  def cookies_page
    controller.action_name == 'cookie_policy' || controller.action_name == 'cookie_settings'
  end

  def accessibility_statement_page
    controller.action_name == 'accessibility_statement'
  end

  def not_permitted_page
    controller.action_name == 'not_permitted'
  end

  def format_date(date_object)
    date_object&.in_time_zone('London')&.strftime '%e %B %Y'
  end

  def format_date_time(date_object)
    date_object&.in_time_zone('London')&.strftime '%e %B %Y, %l:%M%P'
  end

  def format_date_time_day(date_object)
    date_object&.in_time_zone('London')&.strftime '%e %B %Y, %l:%M%P'
  end

  def format_money(cost, precision = 2)
    number_to_currency(cost, precision: precision, unit: '£')
  end

  def govuk_tag(status)
    extra_classes = {
      cannot_start: 'govuk-tag--grey',
      incomplete: 'govuk-tag--red',
      in_progress: 'govuk-tag--blue',
      not_started: 'govuk-tag--grey',
      not_required: 'govuk-tag--grey'
    }

    tag.strong(I18n.t(status, scope: 'shared.tags'), class: ['govuk-tag'] << extra_classes[status])
  end

  def govuk_tag_with_text(colour, text)
    extra_classes = {
      grey: 'govuk-tag--grey',
      blue: 'govuk-tag',
      red: 'govuk-tag--red'
    }

    tag.strong(text, class: ['govuk-tag'] << extra_classes[colour])
  end

  def da_eligible?(code)
    CCS::FM::Rate.where.not(framework: nil).map(&:code).include? code
  end

  def service_specification_document
    link_to_public_file_for_download(t('facilities_management.documents.service_specification_document.name'), :pdf, t('facilities_management.documents.service_specification_document.text'), true, alt: t('facilities_management.select_services.servicespec_link_alttext'))
  end

  def govuk_radio_driver
    tag.div(t('common.radio_driver'), class: 'govuk-radios__divider')
  end

  def warning_text(text)
    tag.div(class: 'govuk-warning-text') do
      concat(tag.span('!', class: 'govuk-warning-text__icon', aria: { hidden: true }))
      concat(
        tag.strong(class: 'govuk-warning-text__text') do
          concat(tag.span('Warning', class: 'govuk-warning-text__assistive'))
          concat(text)
        end
      )
    end
  end

  def create_find_address_helper(object, organisaiton_prefix, object_name, postcode_name)
    @find_address_helper = FacilitiesManagement::FindAddressHelper.new(object, organisaiton_prefix)

    capture do
      concat(hidden_field_tag(:object_name, object_name))
      concat(hidden_field_tag(:postcode_name, postcode_name))
    end
  end

  def hidden_class(visible)
    'govuk-visually-hidden' unless visible
  end

  def input_visible?(visible)
    visible ? 0 : -1
  end

  def search_box(placeholder_text, column = 0)
    text_field_tag 'fm-table-filter-input', nil, class: 'govuk-input', placeholder: placeholder_text, data: { column: column }
  end

  def link_to_public_file_for_download(filename, file_type, text, show_doc_image, **html_options)
    link_to_file_for_download("/#{filename}?format=#{file_type}", file_type, text, show_doc_image, **html_options)
  end

  def link_to_generated_file_for_download(filename, file_type, text, show_doc_image, **html_options)
    link_to_file_for_download("#{filename}?format=#{file_type}", file_type, text, show_doc_image, **html_options)
  end

  def link_to_file_for_download(file_link, file_type, text, show_doc_image, **html_options)
    link_to(file_link, class: ('supplier-record__file-download' if show_doc_image).to_s, type: t("common.type_#{file_type}"), download: '', **html_options) do
      capture do
        concat(text)
        concat(tag.span(t("common.#{file_type}_html"), class: 'govuk-visually-hidden')) if show_doc_image
      end
    end
  end

  def cookie_policy_path
    case params[:service]
    when 'facilities_management/admin'
      facilities_management_admin_cookie_policy_path
    when 'facilities_management/supplier'
      facilities_management_supplier_cookie_policy_path
    when 'crown_marketplace'
      crown_marketplace_cookie_policy_path
    else
      facilities_management_cookie_policy_path
    end
  end

  def cookie_settings_path
    case params[:service]
    when 'facilities_management/admin'
      facilities_management_admin_cookie_settings_path
    when 'facilities_management/supplier'
      facilities_management_supplier_cookie_settings_path
    when 'crown_marketplace'
      crown_marketplace_cookie_settings_path
    else
      facilities_management_cookie_settings_path
    end
  end

  def accessibility_statement_path
    case params[:service]
    when 'facilities_management/admin'
      facilities_management_admin_accessibility_statement_path
    when 'facilities_management/supplier'
      facilities_management_supplier_accessibility_statement_path
    when 'crown_marketplace'
      crown_marketplace_accessibility_statement_path
    else
      facilities_management_accessibility_statement_path
    end
  end
end
# rubocop:enable Metrics/ModuleLength
