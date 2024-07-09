module FacilitiesManagement
  module RM6232
    class FileImporterHelper
      def initialize(**options)
        @package = Axlsx::Package.new
        @sheets = options[:sheets]
        @headers = options[:headers]
        @extra_supplier = options[:extra_supplier] || []
        @empty = options[:empty] || false
      end

      def write
        File.write(self.class::OUTPUT_PATH, @package.to_stream.read, binmode: true)
      end

      def self.sheets_with_extra_headers(sheets_with_extra_headers)
        self::SHEETS.map do |sheet|
          headers = self::HEADERS
          headers += ['Extra'] if sheets_with_extra_headers.include? sheet
          headers
        end
      end

      def suppliers(sheet_name)
        supplier_set = case sheet_name[-1]
                       when 'a'
                         SUPPLIERS_LOT_A
                       when 'b'
                         SUPPLIERS_LOT_B
                       when 'c'
                         SUPPLIERS_LOT_C
                       end

        supplier_set = supplier_set.map { |supplier| [supplier[0], supplier[2]] }
        supplier_set += [@extra_supplier] if @extra_supplier.present?
        supplier_set
      end

      SUPPLIERS_LOT_A = [
        ['Rex LTD', 'Yes', '123456789', '0123456', '1 Pyra road', nil, 'Argentum', nil, 'AA3 1XC', 'Active'],
        ['Nia Corp', 'No', '234567891', '0234567', '2 Dromarch avenue', nil, 'Gromott', nil, 'AA3 2XC', 'Active'],
        ['Tora LTD', 'Yes', '345678912', '0345678', '3 Poppi path', nil, 'Torigoth', nil, 'AA3 3XC', 'Inactive']
      ].freeze

      SUPPLIERS_LOT_B = [
        ['Tora LTD', 'Yes', '345678912', '0345678', '3 Poppi path', nil, 'Torigoth', nil, 'AA3 3XC', 'Inactive'],
        ['Vandham Eexc Corp', 'No', '456789123', '0456789', '4 Roc lane', nil, 'Garfont', nil, 'AA3 4XC', 'Active'],
        ['Morag Jewel LTD', 'Yes', '567891234', '0567891', '5 Brighid boulevard', nil, 'Mor Ardain', nil, 'AA3 5XC', 'Active']
      ].freeze

      SUPPLIERS_LOT_C = [
        ['Morag Jewel LTD', 'Yes', '567891234', '0567891', '5 Brighid boulevard', nil, 'Mor Ardain', nil, 'AA3 5XC', 'Active'],
        ['ZEKE VON GEMBU Corp', 'No', '678912345', '0678912', '6 Pandoria house', nil, 'Tantal', nil, 'AA3 6XC', 'Inactive'],
        ['Jin Corp', 'Yes', '789123456', '0789123', '7 Lora lane', nil, 'Torna', nil, 'AA3 7XC', 'Active']
      ].freeze

      SHEETS = ['Lot 1a', 'Lot 1b', 'Lot 1c', 'Lot 2a', 'Lot 2b', 'Lot 2c', 'Lot 3a', 'Lot 3b', 'Lot 3c'].freeze
    end

    class SupplierDetailsFile < FileImporterHelper
      def initialize(**options)
        options[:sheets] ||= SHEETS
        options[:headers] ||= [HEADERS] * options[:sheets].count
        @status = options[:headers].first.include? 'Status'

        super
      end

      def build
        @sheets.zip(@headers).each do |sheet_name, header_row|
          add_supplier_sheet(sheet_name, header_row)
        end
      end

      OUTPUT_PATH = './tmp/test_supplier_details_file.xlsx'.freeze

      SHEETS = ['RM6232 Suppliers Details'].freeze
      HEADERS = ['Supplier name', 'SME', 'DUNS number', 'Registration number', 'Address line 1', 'Address line 2', 'Town', 'County', 'Postcode'].freeze

      private

      def add_supplier_sheet(sheet_name, header_row)
        supplier_details = (SUPPLIERS_LOT_A + SUPPLIERS_LOT_B + SUPPLIERS_LOT_C).uniq
        supplier_details += [@extra_supplier] if @extra_supplier.present?
        final_index = @status ? -1 : -2

        @package.workbook.add_worksheet(name: sheet_name) do |sheet|
          sheet.add_row header_row
          next if @empty

          supplier_details.each do |supplier_detail|
            sheet.add_row supplier_detail[..final_index]
          end
        end
      end
    end

    class SupplierServicesFile < FileImporterHelper
      def initialize(**options)
        options[:sheets] ||= SHEETS
        options[:headers] ||= self.class.generate_headers

        super
      end

      def self.sheets_with_extra_headers(sheets_with_extra_headers)
        self::SHEETS.zip(generate_headers).map do |sheet, sheet_headers|
          headers = sheet_headers
          headers += ['Extra'] if sheets_with_extra_headers.include? sheet
          headers
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def self.work_packages
        @work_packages ||= {
          '1' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(total: true, core: false) }.reject(&:empty?),
          '2' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(hard: true, core: false) }.reject(&:empty?),
          '3' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(soft: true, core: false) }.reject(&:empty?)
        }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def self.service_columns(lot_number)
        work_packages[lot_number].map do |work_package_services|
          work_package = work_package_services.first.work_package

          [["Work Package #{work_package.code} - #{work_package.name}", nil]] +
            work_package_services.map do |service|
              ["Service #{service.code.gsub('.', ':')} - #{service.name}", "S#{service.code.gsub('.', '')}"]
            end +
            [[nil, nil]]
        end.flatten(1)[0..-2]
      end

      OUTPUT_PATH = './tmp/test_supplier_services_file.xlsx'.freeze

      def self.generate_headers
        %w[1 2 3].map { |lot_number| [service_columns(lot_number)] * 3 }.flatten(1)
      end

      def build
        @sheets.zip(@headers).each do |sheet_name, header_columns|
          add_services_sheet(sheet_name, header_columns)
        end
      end

      private

      def add_services_sheet(sheet_name, header_columns)
        supplier_names, supplier_duns, supplier_options = if @empty
                                                            [[], [], []]
                                                          else
                                                            suppliers = suppliers(sheet_name).transpose
                                                            suppliers + [(['Yes', 'Yes'] + (['No'] * (suppliers.first.length - 2)))]
                                                          end

        @package.workbook.add_worksheet(name: sheet_name) do |sheet|
          sheet.add_row ['If you are bidding for Lot 1a, please confirm within the Yellow highlighted cells, that you are able to provide the relevant additional service']
          sheet.add_row ([nil] * 4) + supplier_names
          sheet.add_row ([nil] * 4) + supplier_duns
          sheet.add_row ['Work package Description', 'Work Package Standard Reference (where applicable)', 'Work Package Section Reference', 'Service', 'Are you able to provide this additional service?']

          header_columns.each do |service_name_cell, service_code_cell|
            supplier_row = service_code_cell.nil? ? [] : supplier_options.rotate!

            sheet.add_row [service_name_cell, service_code_cell, 1, 'Additional'] + supplier_row
          end
        end
      end
    end

    class SupplierRegionsFile < FileImporterHelper
      def initialize(**options)
        options[:sheets] ||= SHEETS
        options[:headers] ||= [HEADERS] * 9

        super
      end

      HEADERS = (['Supplier', 'DUNS Number'] + FacilitiesManagement::Region.all.map(&:code)[0..-2] + ['NC01', 'OS01']).freeze
      OUTPUT_PATH = './tmp/test_supplier_regions_file.xlsx'.freeze

      def build
        @sheets.zip(@headers).each do |sheet_name, header_row|
          add_regions_sheet(sheet_name, header_row)
        end
      end

      private

      def add_regions_sheet(sheet_name, header_row)
        supplier_name_and_duns = suppliers(sheet_name)
        selection = ['X', nil, 'X'] * 25

        @package.workbook.add_worksheet(name: sheet_name) do |sheet|
          sheet.add_row header_row
          next if @empty

          supplier_name_and_duns.each do |supplier|
            sheet.add_row supplier + selection.rotate!
          end
        end
      end
    end
  end
end
