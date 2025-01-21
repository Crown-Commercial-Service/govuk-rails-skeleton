module FacilitiesManagement::Admin
  class SupplierFrameworkData
    SUPLLIERS = ['Hirthe-Mills', 'Kulas, Schultz and Moore', 'Rowe, Hessel and Heller'].freeze
    SHEETS = ['Prices', 'Variances'].freeze
    HEADERS = [
      ['Supplier', 'Service Ref', 'Service Name', 'Unit of Measure', 'General office - Customer Facing', 'General office - Non Customer Facing', 'Call Centre Operations', 'Warehouses', 'Restaurant and Catering Facilities', 'Pre-School', 'Primary School', 'Secondary Schools', 'Special Schools', 'Universities and Colleges', 'Community - Doctors, Dentist, Health Clinic', 'Nursing and Care Homes', 'Direct Award Discount %'],
      ['Management Overhead %', 'Corporate Overhead %', 'Profit %', 'London Location Variance Rate (%)', 'Cleaning Consumables per Building User (£)', 'TUPE Risk Premium (DA %)', 'Mobilisation Cost (DA %)']
    ].freeze
    OUTPUT_PATH = './tmp/test_supplier_framework_date_file.xlsx'.freeze

    def initialize(**options)
      @package = Axlsx::Package.new
      @sheets = options[:sheets] || SHEETS
      @headers = options[:headers] || HEADERS
      @error_type = options[:error_type]
      @normal_supplier = options[:normal_supplier]
    end

    def build
      @sheets.zip(@headers).each do |sheet_name, header_row|
        case sheet_name
        when 'Prices'
          add_prices_sheet(header_row)
        when 'Variances'
          add_variances_sheet(header_row)
        else
          add_other_sheet(sheet_name)
        end
      end
    end

    def write
      File.write(OUTPUT_PATH, @package.to_stream.read, binmode: true)
    end

    private

    def add_prices_sheet(header_row)
      @package.workbook.add_worksheet(name: 'Prices') do |sheet|
        sheet.add_row header_row

        SUPLLIERS.each do |supplier|
          rates, rates_m_and_n = if supplier == @normal_supplier
                                   [PRICES_AND_DISCOUNTS_ROW, PRICES_AND_DISCOUNTS_ROW_M_AND_N]
                                 else
                                   [supplier_prices_and_discounts, supplier_prices_and_discounts_m_and_n]
                                 end

          service_rows.each do |service_row|
            if ['M.1', 'N.1'].include?(service_row[0])
              sheet.add_row [supplier] + service_row + rates_m_and_n
            else
              sheet.add_row [supplier] + service_row + rates
            end
          end
        end
      end
    end

    PRICES_AND_DISCOUNTS_ROW = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0.1].freeze
    PRICES_AND_DISCOUNTS_ROW_M_AND_N = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 0.12, 0.13].freeze

    def supplier_prices_and_discounts
      rates = PRICES_AND_DISCOUNTS_ROW.dup

      return rates unless @error_type

      case @error_type
      when :blank
        rates[rand(12)] = nil
      when :non_numerics
        rates[rand(12)] = 'NaN'
        rates[12] = 'NaN'
      when :greater_than
        rates[rand(12)] = -1
      when :less_than
        rates[12] = 1.001
      end

      rates
    end

    def supplier_prices_and_discounts_m_and_n
      rates = PRICES_AND_DISCOUNTS_ROW_M_AND_N.dup

      return rates unless @error_type

      case @error_type
      when :non_numerics
        rates[rand(12)] = 'NaN'
        rates[12] = 'NaN'
      when :less_than
        rates[rand(12)] = 1.001
        rates[12] = 1.001
      end

      rates
    end

    def add_variances_sheet(header_column)
      variances = supplier_variances
      variances_cleaning = supplier_variances_cleaning

      @package.workbook.add_worksheet(name: 'Variances') do |sheet|
        sheet.add_row ['Supplier'] + SUPLLIERS

        header_column.each do |variance|
          if variance == 'Cleaning Consumables per Building User (£)'
            sheet.add_row([variance] + variances_cleaning)
          else
            sheet.add_row([variance] + variances)
          end
        end
      end
    end

    def supplier_variances
      rates = [0.1, 0.2, 0.3]

      return rates unless @error_type

      case @error_type
      when :non_numerics
        rates[0] = 'NaN'
      when :less_than
        rates[1] = 1.001
      end

      rates
    end

    def supplier_variances_cleaning
      rates = [1, 2, 3]

      return rates unless @error_type

      case @error_type
      when :blank
        rates[0] = nil
      when :non_numerics
        rates[1] = 'NaN'
      when :greater_than
        rates[2] = -1
      end

      rates
    end

    def add_other_sheet(sheet_name)
      @package.workbook.add_worksheet(name: sheet_name) do |sheet|
        sheet.add_row ['EXTRA SHEET']
      end
    end

    def da_service_codes
      @da_service_codes ||= FacilitiesManagement::RM3830::Rate.where(direct_award: true).pluck(:code)
    end

    def work_packages
      @work_packages ||= FacilitiesManagement::RM3830::StaticData.work_packages.select { |work_package| da_service_codes.include? work_package['code'] }
    end

    def service_rows
      @service_rows ||= work_packages.map do |service|
        [service['code'], service_name(service), service_unit(service)]
      end
    end

    def service_name(service)
      if service['has_standards']
        "#{service['name']} - Standard A"
      else
        service['name']
      end
    end

    def service_unit(service)
      if service['unit_text']
        service['unit_text']
      elsif ['M.1', 'N.1'].include?(service['code'])
        'Percentage of Year 1 Deliverables Value (excluding Management and Corporate Overhead, and Profit) at call-off.'
      end
    end
  end
end
