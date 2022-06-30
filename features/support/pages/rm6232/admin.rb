module Pages::RM6232
  class LotData < SitePrism::Section
    section :services, 'dl > div:nth-child(1)' do
      elements :names, 'details > div > ul > li'
      element :change_link, 'dd.govuk-summary-list__actions > a'
    end
    section :regions, 'dl > div:nth-child(2)' do
      elements :names, 'details > div > ul > li'
      element :change_link, 'dd.govuk-summary-list__actions > a'
    end
  end

  class Admin < SitePrism::Page
    sections :suppliers, '#fm-table-filter > tbody > tr', visible: true do
      element :supplier_name, 'th'
      element :'View details', 'td:nth-child(2) > a'
      element :'View lot data', 'td:nth-child(3) > a'
    end

    element :supplier_search_input, '#fm-table-filter-input'

    element :supplier_name_sub_title, '#main-content > div:nth-child(3) > div > span'

    sections :lot_data_tables, '.lot-data-table' do
      element :title, 'h2'
    end

    section :supplier_detail_form, 'form' do
      element :'Supplier name', '#facilities_management_rm6232_admin_suppliers_admin_supplier_name'
      element :'DUNS number', '#facilities_management_rm6232_admin_suppliers_admin_duns'
      element :'Company registration number', '#facilities_management_rm6232_admin_suppliers_admin_registration_number'
    end

    section :lot_data, '#main-content' do
      section :lot_1a, LotData, '#lot-data_table--lot-1a'
      section :lot_1b, LotData, '#lot-data_table--lot-1b'
      section :lot_1c, LotData, '#lot-data_table--lot-1c'
      section :lot_2a, LotData, '#lot-data_table--lot-2a'
      section :lot_2b, LotData, '#lot-data_table--lot-2b'
      section :lot_2c, LotData, '#lot-data_table--lot-2c'
      section :lot_3a, LotData, '#lot-data_table--lot-3a'
      section :lot_3b, LotData, '#lot-data_table--lot-3b'
      section :lot_3c, LotData, '#lot-data_table--lot-3c'
    end

    element :active_true, '#facilities_management_rm6232_admin_suppliers_admin_active_true'
    element :active_false, '#facilities_management_rm6232_admin_suppliers_admin_active_false'
  end
end
