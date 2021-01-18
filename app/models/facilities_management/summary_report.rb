module FacilitiesManagement
  class SummaryReport
    attr_reader :sum_uom, :sum_benchmark, :contract_length_years, :start_date, :tupe_flag,
                :posted_services, :posted_locations, :subregions, :results

    def initialize(procurement_id)
      @sum_uom = 0
      @sum_benchmark = 0
      @procurement = FacilitiesManagement::Procurement.find(procurement_id)
      initialize_from_procurement

      frozen_rates = CCS::FM::FrozenRate.where(facilities_management_procurement_id: procurement_id)
      @rates = frozen_rates.read_benchmark_rates unless frozen_rates.size.zero?
      @rates = CCS::FM::Rate.read_benchmark_rates if frozen_rates.size.zero?

      frozen_ratecard = CCS::FM::FrozenRateCard.where(facilities_management_procurement_id: procurement_id)
      @rate_card = frozen_ratecard.latest unless frozen_ratecard.size.zero?
      @rate_card = CCS::FM::RateCard.latest if frozen_ratecard.size.zero?
      regions
    end

    def initialize_from_procurement
      @start_date = @procurement.initial_call_off_start_date
      @user_id = @procurement.user.id
      @active_procurement_buildings = @procurement.active_procurement_buildings
      @procurement_building_services = @procurement.procurement_building_services
      @posted_services = @procurement_building_services.map(&:code)
      @posted_locations = @active_procurement_buildings.map(&:address_region_code)
      @contract_length_years = @procurement.initial_call_off_period_years.to_i
      @contract_cost = @procurement.estimated_cost_known? ? @procurement.estimated_annual_cost.to_f : 0
      @tupe_flag = @procurement.tupe
    end

    def calculate_services_for_buildings(supplier_id = nil, spreadsheet_type = nil, remove_cafm_help = true)
      @sum_uom = 0
      @sum_benchmark = 0
      @results = {}

      @active_procurement_buildings.includes(:procurement_building_services).find_each do |building|
        procurement_building_services = building.procurement_building_services
        result = uvals_for_building(building, procurement_building_services, spreadsheet_type)
        vals_per_building = services(building, result, remove_cafm_help, supplier_id)
        @sum_uom += vals_per_building[:sum_uom]
        if supplier_id
          # for da spreadsheet
          @results[building.building_id] = vals_per_building[:results]
        else
          @sum_benchmark += vals_per_building[:sum_benchmark]
        end
      end
    end

    def selected_suppliers(for_lot)
      SupplierDetail.selected_suppliers(for_lot, @posted_locations, @posted_services)
    end

    def assessed_value
      @assessed_value ||= calculate_assessed_value
    end

    def direct_award_value
      @sum_uom
    end

    def buyer_input
      @buyer_input ||= @contract_cost * @contract_length_years.to_f
    end

    def current_lot
      return @procurement.lot_number if @procurement.lot_number_selected_by_customer

      case assessed_value
      when 0..7000000
        '1a'
      when 7000000..50000000
        '1b'
      else # when > 50000000
        '1c'
      end
    end

    def move_upto_next_lot(lot)
      case lot
      when nil
        '1a'
      when '1a'
        '1b'
      when '1b'
        '1c'
      else
        lot
      end
    end

    def uvals_for_building(building, procurement_building_services, spreadsheet_type = nil)
      services = spreadsheet_type == :da ? da_procurement_building_services(procurement_building_services) : procurement_building_services

      building_uvals = services.map do |procurement_building_service|
        {
          building_id: building.building_id,
          service_code: procurement_building_service.code,
          uom_value: procurement_building_service.uval,
          service_standard: procurement_building_service.service_standard
        }
      end

      building_uvals
    end

    def da_procurement_building_services(procurement_building_services)
      procurement_building_services.select { |u| u.code.in? procurement_da_services }
    end

    def procurement_da_services
      @procurement_da_services ||= CCS::FM::Service.direct_award_services(@procurement.id)
    end

    def uom_values(spreadsheet_type)
      uvals = @active_procurement_buildings.order_by_building_name.map { |building| uvals_for_building(building, spreadsheet_type) }

      # add labels for spreadsheet
      uvals.each do |u|
        uoms = CCS::FM::UnitsOfMeasurement.service_usage(u['service_code'])
        u['title_text'] = uoms.last['title_text']
        u['example_text'] = uoms.last['example_text']
      end

      @procurement_building_services.each do |s|
        next unless CCS::FM::Service.gia_services.include? s.code

        pc = s.procurement_building
        uvals << { user_id: @procurement.user.id,
                   service_code: s.code.gsub('-', '.'),
                   uom_value: pc.gia.to_f,
                   building_id: pc.building_id,
                   title_text: 'What is the total internal area of this building?',
                   example_text: 'For example, 18000 sqm. When the gross internal area (GIA) measures 18,000 sqm',
                   spreadsheet_label: 'Square Metre (GIA) per annum' }
      end

      uvals
    end

    def values_to_average
      if any_services_missing_framework_price?
        if any_services_missing_benchmark_price?
          return [] if variance_over_30_percent?((sum_uom + sum_benchmark) / 2, buyer_input)
        elsif variance_over_30_percent?(sum_uom, (buyer_input + sum_benchmark) / 2)
          return [sum_benchmark]
        end
      end

      [sum_uom, sum_benchmark]
    end

    private

    def regions
      @subregions = FacilitiesManagement::Region.where(code: posted_locations).map { |region| [region.code, region.name] }.to_h
    end

    def copy_params(procurement_building, uvals)
      @london_flag = building_in_london?(procurement_building.address_region_code)
      @gia = procurement_building.gia
      @external_area = procurement_building.external_area
      @helpdesk_flag = uvals.any? { |uval| uval[:service_code] == 'N.1' }
      @cafm_flag = uvals.any? { |uval| uval[:service_code] == 'M.1' }
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    def services(building, uvals, remove_cafm_help, supplier_id = nil)
      sum_uom = 0.0
      sum_benchmark = 0.0
      results = {}

      copy_params building, uvals

      uvals_remove_cafm_help = remove_cafm_help == true ? uvals.reject { |x| x[:service_code] == 'M.1' || x[:service_code] == 'N.1' } : uvals
      uvals_remove_cafm_help.each do |v|
        uom_value = v[:uom_value]

        if v[:service_code] == 'G.3' || (v[:service_code] == 'G.1')
          occupants = v[:uom_value].to_i
          uom_value = @gia.to_f
        elsif v[:service_code] == 'G.5'
          occupants = 0
          uom_value = @external_area.to_f
        else
          occupants = 0
        end

        calc_fm = FMCalculator::Calculator.new(@contract_length_years,
                                               v[:service_code],
                                               v[:service_standard],
                                               uom_value,
                                               occupants,
                                               @tupe_flag,
                                               @london_flag,
                                               @cafm_flag,
                                               @helpdesk_flag,
                                               @rates,
                                               @rate_card,
                                               supplier_id,
                                               building)
        sum_uom += calc_fm.sumunitofmeasure
        if supplier_id
          results[v[:service_code]] = calc_fm.results
        else
          sum_benchmark += calc_fm.benchmarkedcostssum
        end
      end
      return { sum_uom: sum_uom, results: results } if supplier_id

      { sum_uom: sum_uom,
        sum_benchmark: sum_benchmark }
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # london nuts are defined in FM-703
    def building_in_london?(code)
      %w[UKI3 UKI4 UKI5 UKI6 UKI7].include? code
    end

    def calculate_assessed_value
      return buyer_input if buyer_input != 0.0 && sum_uom == 0.0 && sum_benchmark == 0.0

      values = buyer_input.zero? ? values_if_no_buyer_input : values_to_average

      values << buyer_input unless buyer_input.zero?
      (values.sum / values.size).to_f
    end

    def values_if_no_buyer_input
      if any_services_missing_framework_price? && !any_services_missing_benchmark_price?
        variance_over_30_percent?(sum_uom, sum_benchmark) ? [sum_benchmark] : [(sum_benchmark + sum_uom) / 2]
      else
        [sum_uom, sum_benchmark]
      end
    end

    def any_services_missing_framework_price?
      @procurement.any_services_missing_framework_price?
    end

    def any_services_missing_benchmark_price?
      @procurement.any_services_missing_benchmark_price?
    end

    def variance_over_30_percent?(new, baseline)
      variance = (new - baseline) / baseline

      variance > 0.3 || variance < -0.3
    end
  end
end
