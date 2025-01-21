module FacilitiesManagement::RM6232
  module Admin
    class FilesImporter::FilesChecker < FacilitiesManagement::FilesImporter::FilesChecker
      def check_files
        CHECK_FILES_AND_METHODS.each do |file, check_method|
          read_spreadsheet(file) do |workbook|
            send(check_method, workbook)
          end
        end

        @errors
      end

      private

      def check_supplier_details_spreadsheet(supplier_details_workbook)
        if supplier_details_workbook.sheets != ['RM6232 Suppliers Details']
          @errors << { error: 'supplier_details_missing_sheets' }
        elsif supplier_details_workbook.sheet('RM6232 Suppliers Details').last_row == 1
          @errors << { error: 'supplier_details_has_empty_sheets' }
        elsif [SUPPLIER_DETAILS_HEADERS, SUPPLIER_DETAILS_HEADERS_ACTIVE].exclude?(supplier_details_workbook.sheet('RM6232 Suppliers Details').row(1))
          @errors << { error: 'supplier_details_has_incorrect_headers' }
        end
      end

      def check_supplier_services_spreadsheet(supplier_services_workbook)
        check_sheets(supplier_services_workbook, SHEET_NAMES, 'supplier_services') do |sheets_with_errors, empty_sheets, index|
          if supplier_services_workbook.sheet(index).last_column <= 5
            empty_sheets << SHEET_NAMES[index]
          elsif !services_correct(supplier_services_workbook.sheet(index), index)
            sheets_with_errors << SHEET_NAMES[index]
          end
        end
      end

      def check_supplier_regions_spreadsheet(supplier_regions_workbook)
        check_sheets(supplier_regions_workbook, SHEET_NAMES, 'supplier_regions') do |sheets_with_errors, empty_sheets, index|
          if supplier_regions_workbook.sheet(index).last_row == 1
            empty_sheets << SHEET_NAMES[index]
          elsif supplier_regions_workbook.sheet(index).row(1) != region_sheet_headers
            sheets_with_errors << SHEET_NAMES[index]
          end
        end
      end

      # Shared methods for checking files
      def check_sheets(workbook, expected_sheets, attribute)
        if workbook.sheets == expected_sheets
          sheets_with_errors = []
          empty_sheets = []

          number_of_sheets(workbook).times do |index|
            yield(sheets_with_errors, empty_sheets, index)
          end

          @errors << { error: "#{attribute}_has_incorrect_headers", details: sheets_with_errors } if sheets_with_errors.any?
          @errors << { error: "#{attribute}_has_empty_sheets", details: empty_sheets } if empty_sheets.any?
        else
          @errors << { error: "#{attribute}_missing_sheets" }
        end
      end

      def number_of_sheets(workbook)
        workbook.sheets.size
      end

      # Methods for checking the regions sheet
      # rubocop:disable Metrics/CyclomaticComplexity
      def work_packages
        @work_packages ||= {
          '1' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(total: true, core: false) }.reject(&:empty?),
          '2' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(hard: true, core: false) }.reject(&:empty?),
          '3' => FacilitiesManagement::RM6232::WorkPackage.selectable.map { |work_package| work_package.supplier_services.where(soft: true, core: false) }.reject(&:empty?)
        }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def services_correct(services_sheet, index)
        lot_number = ((index / 3) + 1).to_s

        services_sheet.column(1)[4..] == service_names_column(lot_number) && services_sheet.column(2)[4..] == service_codes_column(lot_number)
      end

      def service_names_column(lot_number)
        work_packages[lot_number].map do |work_package_services|
          work_package = work_package_services.first.work_package

          ["Work Package #{work_package.code} - #{work_package.name}", work_package_services.map { |service| "Service #{service.code.gsub('.', ':')} - #{service.name}" } + [nil]]
        end.flatten[0..-2]
      end

      def service_codes_column(lot_number)
        work_packages[lot_number].map do |work_package_services|
          [nil, work_package_services.map { |service| "S#{service.code.gsub('.', '')}" } + [nil]]
        end.flatten[0..-2]
      end

      def region_sheet_headers
        @region_sheet_headers ||= ['Supplier', 'DUNS Number'] + FacilitiesManagement::Region.all.map(&:code)[0..-2] + ['NC01', 'OS01']
      end

      CHECK_FILES_AND_METHODS = {
        supplier_details_file: :check_supplier_details_spreadsheet,
        supplier_services_file: :check_supplier_services_spreadsheet,
        supplier_regions_file: :check_supplier_regions_spreadsheet
      }.freeze

      SHEET_NAMES = ['Lot 1a', 'Lot 1b', 'Lot 1c', 'Lot 2a', 'Lot 2b', 'Lot 2c', 'Lot 3a', 'Lot 3b', 'Lot 3c'].freeze

      SUPPLIER_DETAILS_HEADERS = ['Supplier name', 'SME', 'DUNS number', 'Registration number', 'Address line 1', 'Address line 2', 'Town', 'County', 'Postcode'].freeze
      SUPPLIER_DETAILS_HEADERS_ACTIVE = SUPPLIER_DETAILS_HEADERS + ['Status']
    end
  end
end
