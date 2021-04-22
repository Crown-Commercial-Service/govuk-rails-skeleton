Then('I enter {string} into the contract name field') do |contract_name|
  @contract_name = contract_name
  procurement_page.contract_name_field.set(contract_name)
end

Then('I have a procurement with the name {string}') do |contract_name|
  create(:facilities_management_procurement, user: @user, contract_name: contract_name)
end

Given('I have an empty procurement for entering requirements named {string}') do |contract_name|
  create(:facilities_management_procurement_entering_requirements, user: @user, contract_name: contract_name)
end

Given('I have an empty procurement for entering requirements named {string} with the following servcies:') do |contract_name, service_codes_table|
  create(:facilities_management_procurement_entering_requirements, user: @user, contract_name: contract_name, service_codes: service_codes_table.raw.flatten)
end

Given('I have an empty procurement with buildings named {string} with the following servcies:') do |contract_name, service_codes_table|
  procurement = create(:facilities_management_procurement_entering_requirements, user: @user, contract_name: contract_name, service_codes: service_codes_table.raw.flatten)

  @user.buildings.each do |building|
    procurement.procurement_buildings.create(building: building, active: true)
  end
end

Given('I have an empty procurement with buildings named {string} with the following servcies assigned:') do |contract_name, service_codes_table|
  service_codes = service_codes_table.raw.flatten

  procurement = create(:facilities_management_procurement_entering_requirements, user: @user, contract_name: contract_name, service_codes: service_codes)

  @user.buildings.each do |building|
    procurement.procurement_buildings.create(building: building, active: true, service_codes: service_codes)
  end
end

Given('I have a procurement in detailed search named {string} with the following services:') do |contract_name, service_codes_table|
  service_codes = service_codes_table.raw.flatten
  procurement = create(:facilities_management_procurement_no_procurement_buildings, user: @user, contract_name: contract_name, service_codes: service_codes, aasm_state: 'detailed_search')
  building = create(:facilities_management_building, building_name: 'Test building', user: @user)
  @procurement_building_id = procurement.procurement_buildings.create(building: building, service_codes: service_codes, active: true).id
end

Given('the GIA for {string} is {int}') do |building_name, gia|
  find_building(building_name).update(gia: gia)
end

Given('the external area for {string} is {int}') do |building_name, external_area|
  find_building(building_name).update(external_area: external_area)
end

def find_building(building_name)
  @user.buildings.find_by(building_name: building_name)
end

Given('I navigate to the service requirements page') do
  visit facilities_management_procurement_building_path(id: @procurement_building_id)
end

Then('I should see my procurement name') do
  expect(procurement_page.contract_name.text).to eq @contract_name
end

Then('I should see my name is {string}') do |contract_name|
  expect(procurement_page.contract_name.text).to eq contract_name
end

Then('Direct award is an available route to market') do
  expect(procurement_page.has_direct_award_route_to_market?).to be true
end

Then('I select {string} on results') do |option|
  case option.downcase
  when 'direct award'
    procurement_page.direct_award_route_to_market.choose
  when 'further competition'
    procurement_page.further_competition_route_to_market.choose
  end
end

Then('the procurement {string} is on the dashboard') do |contract_name|
  expect(procurement_page).to have_link(contract_name)
end

Then('the procurement {string} should have the state {string}') do |contract_name, status|
  expect(procurement_page.find('th', text: contract_name).find(:xpath, '../td[3]')).to have_content(status)
end

Then('the contract name is shown to be {string}') do |contract_name|
  expect(procurement_page.contract_name.text).to eq contract_name
end
