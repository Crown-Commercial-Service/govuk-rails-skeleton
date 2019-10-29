module FacilitiesManagement
  class ProcurementBuildingService < ApplicationRecord
    default_scope { order(created_at: :asc) }
    scope :require_volume, -> { where(code: [REQUIRE_VOLUME_CODES]) }
    scope :has_service_questions, -> { where(code: [SERVICES_AND_QUESTIONS.pluck(:code)]) }
    belongs_to :procurement_building, class_name: 'FacilitiesManagement::ProcurementBuilding', foreign_key: :facilities_management_procurement_building_id, inverse_of: :procurement_building_services

    validates :no_of_appliances_for_testing, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true
    validates :no_of_building_occupants, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true
    validates :no_of_units_to_be_serviced, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true
    validates :size_of_external_area, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true
    validates :no_of_consoles_to_be_serviced, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true
    validates :tones_to_be_collected_and_removed, numericality: { only_integer: true, greater_than: 0, message: :invalid }, allow_blank: true

    REQUIRE_VOLUME_CODES = %w[E.4 G.1 G.3 G.5 K.1 K.2 K.3 K.7 K.4 K.5 K.6].freeze
    SERVICES_AND_QUESTIONS = [{ code: 'C.5', questions: %i[total_floors_per_lift service_standard] },
                              { code: 'E.4', questions: [:no_of_appliances_for_testing] },
                              { code: 'G.1', questions: %i[no_of_building_occupants service_standard] },
                              { code: 'G.3', questions: %i[no_of_building_occupants service_standard] },
                              { code: 'G.5', questions: %i[size_of_external_area service_standard] },
                              { code: 'H.4', questions: [:no_of_hours_of_service_provision] },
                              { code: 'H.5', questions: [:no_of_hours_of_service_provision] },
                              { code: 'I.1', questions: [:no_of_hours_of_service_provision] },
                              { code: 'I.2', questions: [:no_of_hours_of_service_provision] },
                              { code: 'I.3', questions: [:no_of_hours_of_service_provision] },
                              { code: 'I.4', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.1', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.2', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.3', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.4', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.5', questions: [:no_of_hours_of_service_provision] },
                              { code: 'J.6', questions: [:no_of_hours_of_service_provision] },
                              { code: 'K.1', questions: [:no_of_consoles_to_be_serviced] },
                              { code: 'K.2', questions: [:tones_to_be_collected_and_removed] },
                              { code: 'K.3', questions: [:tones_to_be_collected_and_removed] },
                              { code: 'K.4', questions: [:tones_to_be_collected_and_removed] },
                              { code: 'K.5', questions: [:tones_to_be_collected_and_removed] },
                              { code: 'K.6', questions: [:tones_to_be_collected_and_removed] },
                              { code: 'K.7', questions: [:no_of_units_to_be_serviced] },
                              { code: 'C.1', questions: [:service_standard] },
                              { code: 'C.2', questions: [:service_standard] },
                              { code: 'C.3', questions: [:service_standard] },
                              { code: 'C.4', questions: [:service_standard] },
                              { code: 'C.6', questions: [:service_standard] },
                              { code: 'C.7', questions: [:service_standard] },
                              { code: 'C.11', questions: [:service_standard] },
                              { code: 'C.12', questions: [:service_standard] },
                              { code: 'C.13', questions: [:service_standard] },
                              { code: 'C.14', questions: [:service_standard] },
                              { code: 'G.4', questions: [:service_standard] }].freeze

    def requires_volume?
      REQUIRE_VOLUME_CODES.include?(code)
    end
  end
end
