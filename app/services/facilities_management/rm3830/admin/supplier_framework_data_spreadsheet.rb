module FacilitiesManagement::RM3830
  class Admin::SupplierFrameworkDataSpreadsheet
    def build
      create_spreadsheet
    end

    def to_xlsx
      @package.to_stream.read
    end

    private

    def create_spreadsheet
      @package = Axlsx::Package.new
      @workbook = @package.workbook

      add_styles
      create_prices_sheet
      create_variances_sheet
    end

    def add_styles
      @styles = {}

      @workbook.styles do |styles|
        @styles[:heading_style] = styles.add_style sz: 8, alignment: { wrap_text: true, horizontal: :left, vertical: :center }, border: { style: :thin, color: '00000000' }
        @styles[:standard_column_style] = styles.add_style sz: 8, alignment: { wrap_text: false, horizontal: :left, vertical: :center }, border: { style: :thin, color: '00000000' }
      end
    end

    def create_prices_sheet
      @workbook.add_worksheet(name: 'Prices') do |sheet|
        sheet.add_row ['Supplier', 'Service Ref', 'Service Name', 'Unit of Measure', 'General office - Customer Facing', 'General office - Non Customer Facing', 'Call Centre Operations', 'Warehouses', 'Restaurant and Catering Facilities', 'Pre-School', 'Primary School', 'Secondary Schools', 'Special Schools', 'Universities and Colleges', 'Community - Doctors, Dentist, Health Clinic', 'Nursing and Care Homes', 'Direct Award Discount %'], style: @styles[:heading_style]

        suppliers.each do |supplier|
          service_rows.each do |service_row|
            sheet.add_row [supplier] + service_row + ([nil] * 13), style: @styles[:standard_column_style]
          end
        end

        sheet.column_widths(*PRICES_COLUMNS_WIDTHS)
      end
    end

    def create_variances_sheet
      @workbook.add_worksheet(name: 'Variances') do |sheet|
        sheet.add_row ['Supplier'] + suppliers, style: @styles[:heading_style]

        VARIANCES.each { |variance| sheet.add_row([variance] + ([nil] * suppliers.size), style: @styles[:standard_column_style]) }

        sheet.column_widths(*([40] + ([10] * suppliers.size)))
      end
    end

    def suppliers
      @suppliers ||= SupplierDetail.suppliers_offering_lot('1a')
    end

    def da_service_codes
      @da_service_codes ||= Rate.where(direct_award: true).pluck(:code)
    end

    def work_packages
      @work_packages ||= StaticData.work_packages.select { |work_package| da_service_codes.include? work_package['code'] }
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

    PRICES_COLUMNS_WIDTHS = [16, 19, 59, 35, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13].freeze
    VARIANCES = ['Management Overhead %', 'Corporate Overhead %', 'Profit %', 'London Location Variance Rate (%)', 'Cleaning Consumables per Building User (£)', 'TUPE Risk Premium (DA %)', 'Mobilisation Cost (DA %)'].freeze
  end
end
