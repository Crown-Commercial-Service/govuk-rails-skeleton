module FacilitiesManagement
  class SummaryReport
    attr_reader :sum_uom, :sum_benchmark, :building_data, :contract_length_years, :start_date, :tupe_flag, :posted_services, :posted_locations, :subregions

    # rubocop:disable Metrics/PerceivedComplexity
    def initialize(start_date, user_id, data)
      @start_date = start_date
      @user_id = user_id
      # @data = data

      @posted_services =
        if data['fm-services']
          data['fm-services'].collect { |x| x['code'].gsub('-', '.') }
        else
          data['posted_services']
        end

      @posted_locations =
        if data['fm-locations']
          data['fm-locations'].collect { |x| x['code'] }
        else
          data['posted_locations']
        end

      @contract_length_years = data['fm-contract-length'].to_i
      @contract_cost = data['fm-contract-cost'].to_f

      @tupe_flag =
        begin
          if data['contract-tupe-radio'] == 'yes'
            'Y'
          else
            'N'
          end
        rescue StandardError
          'N'
        end

      @sum_uom = 0
      @sum_benchmark = 0
      @gia_services = CCS::FM::Service.gia_services

      regions
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize
    def calculate_services_for_buildings
      selected_services

      @sum_uom = 0
      @sum_benchmark = 0

      @building_data = CCS::FM::Building.buildings_for_user(@user_id)

      services = selected_services.sort_by(&:code)
      selected_services = services.collect(&:code)
      selected_services = selected_services.map { |s| s.gsub('.', '-') }
      selected_buildings = @building_data.select do |b|
        b_services = b.building_json['services'].collect { |s| s['code'] }
        (selected_services & b_services).any?
      end

      uvals = uom_values(selected_buildings, selected_services)

      selected_buildings.each do |building|
        id = building['building_json']['id']
        vals_per_building = services(building.building_json, (uvals.select { |u| u['building_id'] == id }))
        @sum_uom += vals_per_building[:sum_uom]
        @sum_benchmark += vals_per_building[:sum_uom]
      end
    end
    # rubocop:enable Metrics/AbcSize

    def with_pricing
      # CCS::FM::Rate.non_zero_rate
      services_with_pricing = CCS::FM::Rate.non_zero_rate.map(&:code)

      FacilitiesManagement::Service.all.select do |service|
        (@posted_services.include? service.code) && (services_with_pricing.include? service.code)
      end
    end

    def without_pricing
      # CCS::FM::Rate.zero_rate
      services_without_pricing = CCS::FM::Rate.zero_rate.map(&:code)

      FacilitiesManagement::Service.all.select do |service|
        (@posted_services.include? service.code) && (services_without_pricing.include? service.code)
      end
    end

    def selected_services
      @selected_services = FacilitiesManagement::Service.all.select { |service| @posted_services.include? service.code }
    end

    def selected_suppliers(for_lot)
      suppliers = CCS::FM::Supplier.all.select do |s|
        s.data['lots'].find do |l|
          (l['lot_number'] == for_lot) &&
            (@posted_locations & l['regions']).any? &&
            (@posted_services & l['services']).any?
        end
      end

      suppliers.sort_by! { |supplier| supplier.data['supplier_name'] }
    end

    # if services have no costings, just return the contract cost (do not divide the contract cost by 3 or 2)
    def assessed_value
      buyer_input = @contract_cost * @contract_length_years.to_f
      return buyer_input if buyer_input != 0.0 && @sum_uom == 0.0 && @sum_benchmark == 0.0

      return (@sum_uom + @sum_benchmark + buyer_input) / 3 unless buyer_input.zero?

      (@sum_uom + @sum_benchmark) / 2
    end

    def current_lot
      case assessed_value
      when 0..7000000
        '1a'
      when 7000000..50000000
        '1b'
      else # when > 50000000
        '1c'
      end
    end

    def lot_limit
      case assessed_value
      when 0..7000000
        '£7 Million'
      when 7000000..50000000
        'above £7 Million'
      else
        'above £50 Million'
      end
    end

    # rubocop:disable Metrics/AbcSize
    def uom_values(selected_buildings, selected_services)
      uvals = CCS::FM::UnitOfMeasurementValues.values_for_user(@user_id)
      uvals = uvals.map(&:attributes)

      # add labels for spreadsheet
      uvals.each do |u|
        uoms = CCS::FM::UnitsOfMeasurement.service_usage(u['service_code'])
        u['title_text'] = uoms.last['title_text']
        u['example_text'] = uoms.last['example_text']
      end

      lift_service = uvals.select { |s| s['service_code'] == 'C.5' }
      if lift_service.count.positive?
        lifts_title_text = lift_service.last['title_text']
        lifts_example_text = lift_service.last['title_text']

        uvals.reject! { |u| u['service_code'] == 'C.5' && u['uom_value'] == 'Saved' }

        lifts_per_building.each do |b|
          b['lift_data']['lift_data']['floor-data'].each do |l|
            uvals << { 'user_id' => b['user_id'],
                       'service_code' => 'C.5',
                       'uom_value' => l.first[1],
                       'building_id' => b['building_id'],
                       'title_text' => lifts_title_text,
                       'example_text' => lifts_example_text }
          end
        end
      end

      selected_buildings.each do |b|
        selected_services.each do |s|
          next unless @gia_services.include? s

          s_dot = s.gsub('-', '.')
          uvals << { 'user_id' => b['user_id'],
                     'service_code' => s_dot,
                     'uom_value' => b['building_json']['gia'].to_f,
                     'building_id' => b['building_json']['id'],
                     'title_text' => 'What is the total internal area of this building?',
                     'example_text' => 'For example, 18000 sqm. When the gross internal area (GIA) measures 18,000 sqm' }
        end
      end

      uvals
    end
    # rubocop:enable Metrics/AbcSize

    def lifts_per_building
      lifts_per_building = CCS::FM::Lift.lifts_for_user(@user_id)
      lifts_per_building.map(&:attributes)
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

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def copy_params(building_json)
      @fm_gross_internal_area =
        begin
          building_json['gia'].to_i
        rescue StandardError
          0
        end

      @london_flag =
        begin
          if building_json['isLondon'] == 'Yes'
            'Y'
          else
            'N'
          end
        rescue StandardError
          'N'
        end

      @cafm_flag =
        begin
          if building_json['services'].any? { |x| x['name'] == 'CAFM system' }
            'Y'
          else
            'N'
          end
        rescue StandardError
          'N'
        end

      @helpdesk_flag =
        begin
          if building_json['services'].any? { |x| x['name'] == 'Helpdesk services' }
            'Y'
          else
            'N'
          end
        rescue StandardError
          'N'
        end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def services(building_data, uvals)
      sum_uom = 0.0
      sum_benchmark = 0.0

      copy_params building_data
      # id = building_data['id']

      # with_pricing.each do |service|
      uvals.each do |v|
        # puts service.code
        # puts service.name
        # puts service.mandatory
        # puts service.mandatory?
        # puts service.work_package
        # puts service.work_package.code
        # puts service.work_package.name
        #

        # occupants = occupants(v['service_code'], building_data)
        occupants = v['uom_value'] if v['service_code'] == 'G.3' || (v['service_code'] == 'G.1')

        uom_value = v['uom_value'].to_f

        code = v['service_code'].remove('.')
        calc_fm = FMCalculator::Calculator.new(@contract_length_years, code, uom_value, occupants.to_i, @tupe_flag, @london_flag, @cafm_flag, @helpdesk_flag)
        sum_uom += calc_fm.sumunitofmeasure
        sum_benchmark += calc_fm.benchmarkedcostssum
      end
      { sum_uom: sum_uom,
        sum_benchmark: sum_benchmark }
    rescue StandardError => e
      raise e
    ensure
      { sum_uom: sum_uom,
        sum_benchmark: sum_benchmark }
    end

    def regions
      # Get nuts regions
      # @regions = {}
      # Nuts1Region.all.each { |x| @regions[x.code] = x.name }
      @subregions = {}
      FacilitiesManagement::Region.all.each { |x| @subregions[x.code] = x.name }
      @subregions.select! { |k, _v| posted_locations.include? k }
    end
  end
end
