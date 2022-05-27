Then('{string} should have the status {string} in {string}') do |detail, status, section|
  expect(entering_requirements_page.send(section).send(detail).status.text).to eq status.downcase
end

Then('I select {string} for TUPE required') do |option|
  case option
  when 'Yes'
    entering_requirements_page.tupe_yes.choose
  when 'No'
    entering_requirements_page.tupe_no.choose
  end
end

Then('I enter {string} years and {string} months for the contract period') do |years, months|
  add_contract_period(years, months)
end

Then('I enter {string} year and {string} month for the contract period') do |years, months|
  add_contract_period(years, months)
end

Then('I enter {string} year and {string} months for the contract period') do |years, months|
  add_contract_period(years, months)
end

Then('I enter {string} years and {string} month for the contract period') do |years, months|
  add_contract_period(years, months)
end

Then('I enter {string} as the inital call-off period start date') do |date|
  add_initial_call_off_period_dates(*date_options(date))
end

Then('I enter an inital call-off period start date {int} years and {int} months into the future') do |years, months|
  @initial_call_off_period_start_date = Time.zone.today + years.years + months.months

  add_initial_call_off_period_dates(*@initial_call_off_period_start_date.strftime('%d/%m/%Y').split('/'))
end

Then('I select {string} for mobilisation period required') do |option|
  case option
  when 'Yes'
    entering_requirements_page.mobilisation_period_yes.choose
  when 'No'
    entering_requirements_page.mobilisation_period_no.choose
  end
end

Then('I enter {string} weeks for the mobilisation period') do |mobilisation_period|
  @mobilisation_period = mobilisation_period.to_i

  entering_requirements_page.mobilisation_period.set(mobilisation_period)
end

Then('I select {string} for optional extension required') do |option|
  case option
  when 'Yes'
    entering_requirements_page.extension_required_yes.choose
  when 'No'
    entering_requirements_page.extension_required_no.choose
  end
end

And('only the first optional extension is required') do
  entering_requirements_page.call_off_extensions.send(:'1').required.set(true)
end

Then('I enter {string} years and {string} months for optional extension {int}') do |years, months, extension|
  @contract_extentsions ||= {}
  @contract_extentsions[extension] = years.to_i.years + months.to_i.months

  entering_requirements_page.call_off_extensions.send(:"#{extension}").years.set(years)
  entering_requirements_page.call_off_extensions.send(:"#{extension}").months.set(months)
end

Then('I add another extension') do
  entering_requirements_page.call_off_extensions.add_extension.click
end

Then('I remove extension period {int}') do |extension|
  entering_requirements_page.call_off_extensions.send(:"#{extension}").remove.click
end

Then('the add an extension button should have the text {string}') do |button_text|
  expect(entering_requirements_page.call_off_extensions.add_extension).to have_content(button_text)
end

Then('the add an extension button should be {string}') do |status|
  element_visivility_expectations(entering_requirements_page.call_off_extensions.add_extension, status)
end

Then('the remove button for extension {int} should be {string}') do |extension, status|
  element_visivility_expectations(entering_requirements_page.call_off_extensions.send(:"#{extension}").remove, status)
end

Then('extension {int} should be {string}') do |extension, status|
  case status
  when 'hidden'
    expect(entering_requirements_page.call_off_extensions.send(:"#{extension}")).to have_css('.govuk-visually-hidden')
  when 'visible'
    expect(entering_requirements_page.call_off_extensions.send(:"#{extension}")).not_to have_css('.govuk-visually-hidden')
  end
end

Then('extension {int} should have the following error messages:') do |extension, error_messages|
  expect(entering_requirements_page.call_off_extensions.send(:"#{extension}").error_messages.map(&:text)).to eq error_messages.raw.flatten
end

Then('my inital call off period length is {string}') do |initial_call_off_period_length|
  expect(entering_requirements_page.contract_period_summary.initial_call_off_period_length).to have_content(initial_call_off_period_length)
end

Then('my inital call off period is correct given the contract start date') do
  @initial_call_off_end_date = @initial_call_off_period_start_date + @contract_period_years.years + @contract_period_months.months
  @initial_call_off_end_date -= 1.day if @initial_call_off_period_start_date.day == @initial_call_off_end_date.day
  initial_call_off_period_string = format_date_period(@initial_call_off_period_start_date, @initial_call_off_end_date)

  expect(entering_requirements_page.contract_period_summary.initial_call_off_period).to have_content(initial_call_off_period_string)
end

Then('mobilisation period length is {string}') do |mobilisation_period_length|
  expect(entering_requirements_page.contract_period_summary.mobilisation_period_length).to have_content(mobilisation_period_length)
end

Then('the mobilisation period is correct given the contract start date') do
  mobilisation_period = format_date_period(@initial_call_off_period_start_date - @mobilisation_period.weeks - 1.day, @initial_call_off_period_start_date - 1.day)

  expect(entering_requirements_page.contract_period_summary.mobilisation_period).to have_content(mobilisation_period)
end

Then('there are no optional call off extensions') do
  expect(entering_requirements_page.contract_period_summary.call_off_extension).to have_content('None')
end

Then('the length of extension period {int} is {string}') do |extension, extension_length|
  expect(entering_requirements_page.contract_period_summary.send(:"extension_#{extension}_length")).to have_content(extension_length)
end

Then('extension period {int} is correct given the contract start date') do |extension|
  extension_period = format_date_period(extension_start_date(extension), extension_end_date(extension))

  expect(entering_requirements_page.contract_period_summary.send(:"extension_#{extension}_period")).to have_content(extension_period)
end

def add_contract_period(years, months)
  @contract_period_years = years.to_i
  @contract_period_months = months.to_i

  entering_requirements_page.initial_call_off_period_years.set(years)
  entering_requirements_page.initial_call_off_period_months.set(months)
end

def add_initial_call_off_period_dates(day, month, year)
  entering_requirements_page.initial_call_off_period_day.set(day)
  entering_requirements_page.initial_call_off_period_month.set(month)
  entering_requirements_page.initial_call_off_period_year.set(year)
end

def element_visivility_expectations(element, status)
  case status
  when 'hidden'
    expect(element[:class]).to include('govuk-visually-hidden')
    expect(element[:tabindex]).to eq '-1'
  when 'visible'
    expect(element[:class]).not_to include('govuk-visually-hidden')
    expect(element[:tabindex]).to eq '0'
  end
end

def extension_start_date(extension)
  additional_period = (1..(extension - 1)).sum { |index| @contract_extentsions[index] }

  @initial_call_off_end_date + additional_period + 1.day
end

def extension_end_date(extension)
  additional_period = (1..extension).sum { |index| @contract_extentsions[index] }

  @initial_call_off_end_date + additional_period
end
