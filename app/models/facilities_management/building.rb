require 'uk_postcode'
module FacilitiesManagement
  class Building < ApplicationRecord
    belongs_to :user,
               inverse_of: :buildings

    scope :order_by_building_name, -> { order(Arel.sql('lower(building_name)')) }

    before_validation :determine_status
    before_save :determine_status

    with_options on: %i[all new building_details] do
      validate :remove_excess_spaces_from_building_name
      validates :building_name, presence: true, uniqueness: { scope: :user, error: :taken }, length: { maximum: 50 }
      validates :description, length: { maximum: 50 }
    end

    with_options on: %i[all building_area] do
      validates :gia, :external_area, presence: true
      validates :gia, :external_area, numericality: { only_integer: true, less_than_or_equal_to: 999999999, greater_than_or_equal_to: 0 }
      validate  :combined_external_area_and_gia_greater_than_zero
    end

    with_options on: :all, if: -> { address_postcode.present? } do
      validates :address_line_1, presence: true, length: { maximum: 100 }
      validates :address_line_2, length: { maximum: 100 }
      validates :address_town, presence: true, length: { maximum: 30 }
    end

    with_options on: %i[all new building_details] do
      validates :address_postcode, presence: true, if: -> { address_postcode.blank? }
      validate :postcode_format, if: -> { address_postcode.present? }
      validate :address_selection
      validate :address_region_selection, if: -> { address_postcode.present? && address_line_1.present? }
    end

    with_options on: :add_address do
      validates :address_line_1, presence: true, length: { maximum: 100 }
      validates :address_line_2, length: { maximum: 100 }
      validates :address_town, presence: true, length: { maximum: 30 }
      validates :address_postcode, presence: true
      validate :postcode_format, if: -> { address_postcode.present? }
      after_validation :reselect_region
    end

    with_options on: %i[all building_type] do
      before_validation :prepare_building_type_selection
      validates :building_type, presence: true
      validate :building_type_selection

      with_options if: -> { building_type == 'other' } do
        validates :other_building_type, presence: true
        validate { text_area_max_length(:other_building_type, 150) }
      end
    end

    with_options on: %i[all security_type] do
      before_validation :prepare_security_type_selection
      validates :security_type, presence: true
      validate :security_type_selection

      with_options if: -> { security_type == 'other' } do
        validates :other_security_type, presence: true
        validate { text_area_max_length(:other_security_type, 150) }
      end
    end

    def standard_building_type?
      (BUILDING_TYPES.find { |type| type[:id] == building_type } || { standard_building_type: false })[:standard_building_type]
    end

    def building_standard
      standard_building_type? ? 'STANDARD' : 'NON-STANDARD'
    end

    def full_address
      [address_line_1, address_line_2, address_town, address_region, address_postcode].compact_blank.join(', ')
    end

    def address_no_region
      [address_line_1, address_line_2, address_town, address_postcode].compact_blank.join(', ')
    end

    def add_region_code_from_address_region
      regions = Postcode::PostcodeCheckerV2.find_region address_postcode.delete(' ')
      region = regions.select { |single_region| single_region[:region] == address_region }.first
      return if region.nil?

      self.address_region_code = region[:code]
    end

    def building_status
      if status == 'Ready'
        :completed
      else
        :incomplete
      end
    end

    private

    def determine_status
      self.status = if building_ready?
                      'Ready'
                    else
                      'Incomplete'
                    end
    end

    def remove_excess_spaces_from_building_name
      building_name&.squish!
    end

    def building_ready?
      building_name.present? && address_postcode.present? && address_region_code.present? && building_type.present? && security_type.present? && combined_area_positive?
    end

    def combined_area_positive?
      return false if gia.nil? || external_area.nil?

      (gia.to_i + external_area.to_i).positive?
    end

    def address_selection
      return if address_postcode.blank?

      pc = UKPostcode.parse(address_postcode)
      pc.full_valid? ? errors.delete(:address_postcode) : errors.add(:address_postcode, :invalid)

      errors.add(:base, :not_selected) if address_line_1.blank? && pc.full_valid?
    end

    def postcode_format
      pc = UKPostcode.parse(address_postcode)
      pc.full_valid? ? errors.delete(:address_postcode) : errors.add(:address_postcode, :invalid)
    end

    def combined_external_area_and_gia_greater_than_zero
      return if errors[:gia].any? || errors[:external_area].any? || (gia.to_i + external_area.to_i).positive?

      errors.add(:gia, :combined_area)
      errors.add(:external_area, :combined_area)
    end

    def address_region_selection
      errors.add(:address_region, :blank) unless address_region.present? && address_region_code.present?
    end

    def reselect_region
      return if errors.any? || !address_postcode_changed?

      regions = Postcode::PostcodeCheckerV2.find_region(address_postcode)

      if regions.length == 1
        self.address_region_code = regions.first[:code]
        self.address_region = regions.first[:region]
      else
        self.address_region_code = nil
        self.address_region = nil
      end
    end

    def prepare_building_type_selection
      self.building_type = 'other' if building_type == 'Other'
      return if building_type == 'other'

      self.other_building_type = nil
      convert_building_type
    end

    def prepare_security_type_selection
      self.security_type = 'other' if security_type == 'Other'
      self.other_security_type = nil unless security_type == 'other'
    end

    def text_area_max_length(attribute, maximum)
      errors.add(attribute, :too_long) if self[attribute].present? && self[attribute].gsub("\r\n", "\r").length > maximum
    end

    def building_type_selection
      fm_building_types = BUILDING_TYPES.pluck(:id)

      errors.add(:building_type, :inclusion) unless (fm_building_types + ['other']).include? building_type
    end

    def security_type_selection
      fm_security_types = SecurityType.all&.map(&:title) || []

      errors.add(:security_type, :inclusion) unless (fm_security_types + ['other']).include? security_type
    end

    def convert_building_type
      self.building_type = (BUILDING_TYPES.find { |type| type[:spreadsheet_title] == building_type } || { id: building_type })[:id]
    end

    BUILDING_TYPES = [{ id: 'General office - Customer Facing', title: 'General office - customer facing', caption: 'General office areas and customer facing areas.', spreadsheet_title: 'General office - Customer Facing', standard_building_type: true },
                      { id: 'General office - Non Customer Facing', title: 'General office - non customer facing', caption: 'General office areas and non-customer facing areas.', spreadsheet_title: 'General office - Non Customer Facing', standard_building_type: true },
                      { id: 'Call Centre Operations', title: 'Call centre operations', caption: '', spreadsheet_title: 'Call Centre Operations', standard_building_type: true },
                      { id: 'Warehouses', title: 'Warehouses', caption: 'Large storage facility with limited office space and low density occupation by supplier personnel.', spreadsheet_title: 'Warehouses', standard_building_type: true },
                      { id: 'Restaurant and Catering Facilities', title: 'Restaurant and catering facilities', caption: 'Areas including restaurants, deli-bars, coffee lounges and areas used exclusively for consuming food and beverages.', spreadsheet_title: 'Restaurant and Catering Facilities', standard_building_type: true },
                      { id: 'Pre-School', title: 'Pre-school', caption: 'Pre-school, including crèche, nursery and after-school facilities.', spreadsheet_title: 'Pre-School', standard_building_type: true },
                      { id: 'Primary School', title: 'Primary school', caption: 'Primary school facilities.', spreadsheet_title: 'Primary School', standard_building_type: true },
                      { id: 'Secondary Schools', title: 'Secondary school', caption: 'Secondary school facilities.', spreadsheet_title: 'Secondary School', standard_building_type: true },
                      { id: 'Special Schools', title: 'Special schools', caption: 'Special school facilities.', spreadsheet_title: 'Special Schools', standard_building_type: true },
                      { id: 'Universities and Colleges', title: 'Universities and colleges', caption: 'University and college, including on and off site campus facilities but excluding student residential accommodation facilities.', spreadsheet_title: 'Universities and Colleges', standard_building_type: true },
                      { id: 'Community - Doctors, Dentist, Health Clinic', title: 'Doctors, dentists and health clinics', caption: 'Community led facilities including doctors, dentists and health clinics.', spreadsheet_title: 'Doctors, Dentists and Health Clinics', standard_building_type: true },
                      { id: 'Nursing and Care Homes', title: 'Nursery and care homes', caption: 'Nursery and care home facilities.', spreadsheet_title: 'Nursery and Care Homes', standard_building_type: true },
                      { id: 'Data-Centre-Operations', title: 'Data centre operations', caption: '', spreadsheet_title: 'Data Centre Operations', standard_building_type: false },
                      { id: 'External-parks,-grounds-and-car-parks', title: 'External parks, grounds and car parks', caption: 'External car parks and grounds including externally fixed assets. For example: fences, gates, fountains.', spreadsheet_title: 'External parks, grounds and car parks', standard_building_type: false },
                      { id: 'Laboratory', title: 'Laboratory', caption: 'Includes all Government facilities where the standard of cleanliness is high, access is restricted and is not public facing.', spreadsheet_title: 'Laboratory', standard_building_type: false },
                      { id: 'Heritage-Buildings', title: 'Heritage buildings', caption: 'Buildings of historical or cultural significance.', spreadsheet_title: 'Heritage Buildings', standard_building_type: false },
                      { id: 'Nuclear-Facilities', title: 'Nuclear facilities', caption: 'Areas associated with nuclear activities.', spreadsheet_title: 'Nuclear Facilities', standard_building_type: false },
                      { id: 'Animal-Facilities', title: 'Animal facilities', caption: 'Areas associated with the housing of animals such as dog kennels and stables.', spreadsheet_title: 'Animal Facilities', standard_building_type: false },
                      { id: 'Custodial-Facilities', title: 'Custodial facilities', caption: 'Facilities relating to the detention of personnel such as prisons and detention centres.', spreadsheet_title: 'Custodial Facilities', standard_building_type: false },
                      { id: 'Fire-and-Police-Stations', title: 'Fire and police stations', caption: 'Areas associated with emergency services.', spreadsheet_title: 'Fire and Police Stations', standard_building_type: false },
                      { id: 'Production-Facilities', title: 'Production facilities', caption: 'An environment centered around a fabrication or production facility, typically with restricted access.', spreadsheet_title: 'Production Facilities', standard_building_type: false },
                      { id: 'Workshops', title: 'Workshops', caption: 'Areas where works are undertaken such as joinery or metal working facilities.', spreadsheet_title: 'Workshops', standard_building_type: false },
                      { id: 'Garages', title: 'Garages', caption: 'Areas where motor vehicles are cleaned, serviced, repaired and maintained.', spreadsheet_title: 'Garages', standard_building_type: false },
                      { id: 'Shopping-Centres', title: 'Shopping centres', caption: 'Areas where retail services are delivered to the public.', spreadsheet_title: 'Shopping Centres', standard_building_type: false },
                      { id: 'Museums-or-Galleries', title: 'Museums or galleries', caption: 'Areas that are generally open to the public with some restrictions in place from time to time. Some facilities have no public access.', spreadsheet_title: 'Museums /Galleries', standard_building_type: false },
                      { id: 'Fitness-or-Training-Establishments', title: 'Fitness or training establishments', caption: 'Areas associated with fitness and leisure such as swimming pools, gymnasia, fitness centres and internal or external sports facilities.', spreadsheet_title: 'Fitness / Training Establishments', standard_building_type: false },
                      { id: 'Residential-Buildings', title: 'Residential buildings', caption: 'Residential accommodation or areas.', spreadsheet_title: 'Residential Buildings', standard_building_type: false },
                      { id: 'Port-and-Airport-buildings', title: 'Port and airport buildings', caption: 'Areas associated with air and sea transportation and supporting facilities. For example: airports, aerodromes and dock areas.', spreadsheet_title: 'Port and Airport buildings', standard_building_type: false },
                      { id: 'List-X-Property', title: 'List x property', caption: "A commercial site (that is non-government) on UK soil that is approved to hold UK government protectively marked information marked as 'confidential' and above. It is applied to a company's specific site and not a company as a whole.", spreadsheet_title: 'List X Property', standard_building_type: false },
                      { id: 'Hospitals', title: 'Hospitals', caption: 'Areas including mainstream medical, healthcare facilities such as hospitals and medical centres.', spreadsheet_title: 'Hospitals', standard_building_type: false },
                      { id: 'Mothballed-/-Vacant-/-Disposal', title: 'Mothballed or vacant or disposal', caption: 'Areas which are vacant or awaiting disposal where no services are being undertaken.', spreadsheet_title: 'Mothballed / Vacant / Disposal', standard_building_type: false }].freeze
  end
end
