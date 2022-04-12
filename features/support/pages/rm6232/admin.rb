module Pages::RM6232
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
      element :'Contact name', '#facilities_management_rm6232_admin_suppliers_admin_contact_name'
      element :'Contact email', '#facilities_management_rm6232_admin_suppliers_admin_contact_email'
      element :'Contact telephone number', '#facilities_management_rm6232_admin_suppliers_admin_contact_phone'
      element :'DUNS number', '#facilities_management_rm6232_admin_suppliers_admin_duns'
      element :'Company registration number', '#facilities_management_rm6232_admin_suppliers_admin_registration_number'
    end
  end
end
