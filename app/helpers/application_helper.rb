# rubocop:disable Metrics/ModuleLength
module ApplicationHelper
  include CCS::FrontendHelpers
  include LayoutHelper
  include GovUKHelper
  include HeaderNavigationLinksHelper

  def feedback_email_link
    link_to(t('common.feedback'), Marketplace.fm_survey_link, target: '_blank', rel: 'noopener', class: 'govuk-link')
  end

  def support_telephone_number
    Marketplace.support_telephone_number
  end

  def govuk_form_group_with_optional_error(journey, *attributes, &)
    attributes_with_errors = attributes.select { |a| journey.errors[a].any? }

    css_classes = ['govuk-form-group']
    css_classes += ['govuk-form-group--error'] if attributes_with_errors.any?

    tag.div(class: css_classes, &)
  end

  def govuk_fieldset_with_optional_error(journey, *attributes, &)
    attributes_with_errors = attributes.select { |a| journey.errors[a].any? }

    options = { class: 'govuk-fieldset' }
    options['aria-describedby'] = attributes_with_errors.map { |a| error_id(a) } if attributes_with_errors.any?

    tag.fieldset(**options, &)
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
    title.compact_blank.map(&:strip).join(': ')
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

  def govuk_tag_with_status(status)
    govuk_tag(I18n.t(status, scope: 'shared.tags'), STATUS_TO_COLOUR[status])
  end

  def service_specification_document(framework)
    link_to_public_file_for_download(t("facilities_management.#{framework}.documents.service_specification_document.name"), :pdf, t("facilities_management.#{framework}.documents.service_specification_document.text"), true, alt: t('facilities_management.select_services.servicespec_link_alttext'))
  end

  def govuk_radio_driver
    tag.div(t('common.radio_driver'), class: 'govuk-radios__divider')
  end

  def find_address_helper(object, organisaiton_prefix)
    FacilitiesManagement::FindAddressHelper.new(object, organisaiton_prefix)
  end

  def hidden_class(visible)
    'govuk-visually-hidden' unless visible
  end

  def input_visible?(visible)
    visible ? 0 : -1
  end

  def search_box(placeholder_text, column = 0)
    text_field_tag 'fm-table-filter-input', nil, class: 'govuk-input', placeholder: placeholder_text, data: { column: }
  end

  def link_to_public_file_for_download(filename, file_type, text, show_doc_image, **)
    link_to_file_for_download("/#{filename}?format=#{file_type}", file_type, text, show_doc_image, **)
  end

  def link_to_generated_file_for_download(filename, file_type, text, show_doc_image, **)
    link_to_file_for_download("#{filename}?format=#{file_type}", file_type, text, show_doc_image, **)
  end

  def link_to_file_for_download(file_link, file_type, text, show_doc_image, **)
    link_to(file_link, class: ('supplier-record__file-download' if show_doc_image).to_s, type: t("common.type_#{file_type}"), download: '', **) do
      capture do
        concat(text)
        concat(tag.span(t("common.#{file_type}_html"), class: 'govuk-visually-hidden')) if show_doc_image
      end
    end
  end

  def cookie_policy_path
    "#{service_path_base}/cookie-policy"
  end

  def cookie_settings_path
    "#{service_path_base}/cookie-settings"
  end

  def accessibility_statement_path
    "#{service_path_base}/accessibility-statement"
  end

  def contact_link(link_text)
    link_to(link_text, Marketplace.support_form_link, target: :blank)
  end

  def accordion_region_items(region_codes, with_overseas: false)
    nuts1_regions = Nuts1Region.send(with_overseas ? :all_with_overseas : :all).to_h { |region| [region.code, { name: region.name, items: [] }] }

    FacilitiesManagement::Region.find_each do |region|
      region_group_code = region.code[..2]

      next unless nuts1_regions[region_group_code]

      nuts1_regions[region.code[..2]][:items] << {
        code: region.code,
        value: region.code,
        name: "#{region.name.gsub(160.chr('UTF-8'), ' ')} (#{region.code})",
        selected: region_codes.include?(region.code)
      }
    end

    nuts1_regions
  end

  def rm6232_accordion_service_items(service_codes)
    FacilitiesManagement::RM6232::WorkPackage.selectable.map do |work_package|
      [
        work_package.code,
        {
          name: work_package.name,
          items: work_package.selectable_services.map do |service|
            {
              code: service.code.tr('.', '-'),
              value: service.code,
              name: service.name,
              selected: service_codes&.include?(service.code),
              description: service.description
            }
          end
        }
      ]
    end
  end

  def can_show_new_framework_banner?
    Marketplace.rm6232_live? || params[:show_new_framework_banner].present?
  end

  # rubocop:disable Metrics/ParameterLists
  def link_to_add_row(name, number_of_items, form, association, partial_prefix, **options)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render("#{partial_prefix}/#{association.to_s.singularize}", ff: builder)
    end
    govuk_button(name.gsub('<number_of_items>', number_of_items.to_s), href: '#', classes: options[:class], attributes: { data: { id: id, fields: fields.gsub('\n', ''), 'button-text': name } })
  end
  # rubocop:enable Metrics/ParameterLists

  def cookie_preferences_settings
    @cookie_preferences_settings ||= begin
      current_cookie_preferences = JSON.parse(cookies[Marketplace.cookie_settings_name] || '{}')

      !current_cookie_preferences.is_a?(Hash) || current_cookie_preferences.empty? ? Marketplace.default_cookie_options : current_cookie_preferences
    end
  end

  # rubocop:disable Metrics/AbcSize
  def pagination_params(paginator)
    template = paginator.instance_variable_get(:@template)
    options = paginator.instance_variable_get(:@options)
    current_page = options[:current_page]

    parameters = {}

    parameters[:pagination_previous] = { href: Kaminari::Helpers::PrevPage.new(template, **options).url } unless current_page.first?

    last_page_gap = false

    parameters[:pagination_items] = paginator.each_page.map do |page|
      if page.display_tag?
        last_page_gap = false

        {
          type: :number,
          href: Kaminari::Helpers::Page.new(template, **options.merge(page:)).url,
          number: page.number,
          current: page.current?
        }
      elsif !last_page_gap
        last_page_gap = true

        {
          type: :ellipsis
        }
      end
    end.compact

    parameters[:pagination_next] = { href: Kaminari::Helpers::NextPage.new(template, **options).url } if !current_page.out_of_range? && !current_page.last?

    parameters
  end
  # rubocop:enable Metrics/AbcSize

  STATUS_TO_COLOUR = {
    cannot_start: :grey,
    incomplete: :red,
    not_started: :grey,
    not_required: :grey
  }.freeze
end
# rubocop:enable Metrics/ModuleLength
