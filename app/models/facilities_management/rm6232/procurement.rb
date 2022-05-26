module FacilitiesManagement
  module RM6232
    class Procurement < ApplicationRecord
      include AASM
      include ProcurementValidator

      scope :searches, -> { where(aasm_state: SEARCH).select(:id, :contract_name, :aasm_state, :updated_at).order(updated_at: :asc).sort_by { |search| SEARCH.index(search.aasm_state) } }
      scope :advanced_procurement_activities, -> { further_competition.select(:id, :contract_name, :contract_number, :updated_at).order(updated_at: :asc) }

      belongs_to :user, inverse_of: :rm6232_procurements

      before_create :generate_contract_number, :determine_lot_number

      # The service CAFM – Soft FM Requirements (Q.1) can only be selected when all other services are soft.
      # Because we don't want to pass that logic onto the user, we determine which CAFM service they need for them.
      # To make the selection easier we have added the Q.3 service for the user to select,
      # which we can then replace with the correct CAFM service at the appropriate time.
      # You can read more information at: https://crowncommercialservice.atlassian.net/l/c/XW2DSi72

      def quick_view_suppliers
        @quick_view_suppliers ||= SuppliersSelector.new(service_codes_without_cafm, region_codes, annual_contract_value)
      end

      def services
        @services ||= Service.where(code: true_service_codes).order(:work_package_code, :sort_order)
      end

      def regions
        @regions ||= Region.where(code: region_codes)
      end

      aasm do
        state :what_happens_next, initial: true
        state :entering_requirements
        state :results
        state :further_competition

        event :set_to_next_state do
          transitions from: :what_happens_next, to: :entering_requirements
          transitions from: :entering_requirements, to: :results
          transitions from: :results, to: :further_competition
        end
      end

      SEARCH = %w[what_happens_next entering_requirements results].freeze

      def contract_name_status
        contract_name.present? ? :completed : :not_started
      end

      def annual_contract_value_status
        annual_contract_value.present? ? :completed : :not_started
      end

      def tupe_status
        tupe.nil? ? :not_started : :completed
      end

      def contract_period_status
        # TODO: Add in when appropriate
        # relevant_attributes = [
        #   initial_call_off_period_years,
        #   initial_call_off_period_months,
        #   initial_call_off_start_date,
        #   mobilisation_period_required,
        #   extensions_required
        # ]

        # return :not_started if relevant_attributes.all?(&:nil?)

        # relevant_attributes.any?(&:nil?) ? :incomplete : :completed
        :not_started
      end

      def services_status
        @services_status ||= service_codes.any? ? :completed : :not_started
      end

      def buildings_status
        # TODO: Add in when appropriate
        # @buildings_status ||= active_procurement_buildings.any? ? :completed : :not_started
        :not_started
      end

      def buildings_and_services_status
        # TODO: Add in when appropriate
        # @buildings_and_services_status ||= if services_status == :not_started || buildings_status == :not_started
        #                                      :cannot_start
        #                                    else
        #                                      buildings_and_services_completed? ? :completed : :incomplete
        #                                    end
        :cannot_start
      end

      private

      def service_codes_without_cafm
        service_codes - ['Q.3']
      end

      def true_service_codes
        return service_codes unless service_codes.include?('Q.3')

        if lot_number.start_with? '3'
          service_codes_without_cafm + ['Q.1']
        else
          service_codes_without_cafm + ['Q.2']
        end
      end

      def generate_contract_number
        self.contract_number = ContractNumberGenerator.new(framework: 'RM6232', model: self.class).new_number
      end

      def determine_lot_number
        self.lot_number = Service.find_lot_number(service_codes_without_cafm, annual_contract_value)
      end
    end
  end
end
