require 'rails_helper'

RSpec.feature 'Temp to Perm fee calculator', type: :feature do
  scenario 'Hiring a worker within 12 weeks of the start of their contract' do
    visit_supply_teachers_start

    choose I18n.t('supply_teachers.journey.looking_for.answer_calculate_temp_to_perm_fee')
    click_on I18n.t('common.submit')

    fill_in 'contract_start_date_day', with: 3
    fill_in 'contract_start_date_month', with: 9
    fill_in 'contract_start_date_year', with: 2018

    fill_in 'hire_date_day', with: 19
    fill_in 'hire_date_month', with: 11
    fill_in 'hire_date_year', with: 2018

    fill_in 'days_per_week', with: 5

    fill_in 'day_rate', with: 110

    fill_in 'markup_rate', with: 10

    click_on I18n.t('common.submit')

    expect(page).to have_text('Based on the information provided you could be charged £50')
  end

  scenario 'Hiring a worker after 12 weeks of the start of their contract but without enough notice period' do
    visit_supply_teachers_start

    choose I18n.t('supply_teachers.journey.looking_for.answer_calculate_temp_to_perm_fee')
    click_on I18n.t('common.submit')

    fill_in 'contract_start_date_day', with: 3
    fill_in 'contract_start_date_month', with: 9
    fill_in 'contract_start_date_year', with: 2018

    fill_in 'hire_date_day', with: 26
    fill_in 'hire_date_month', with: 11
    fill_in 'hire_date_year', with: 2018

    fill_in 'days_per_week', with: 5

    fill_in 'day_rate', with: 110

    fill_in 'markup_rate', with: 10

    fill_in 'notice_date_day', with: 26
    fill_in 'notice_date_month', with: 11
    fill_in 'notice_date_year', with: 2018

    click_on I18n.t('common.submit')

    expect(page).to have_text('Based on the information provided you could be charged £200')
  end
end
