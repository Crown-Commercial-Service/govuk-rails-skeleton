module SupplyTeachers::TempToPermCalculatorHelper
  def display_notice_period_required(calculator)
    t('supply_teachers.home.temp_to_perm_fee.notice_period_required',
      days: calculator.days_notice_required)
  end

  def display_notice_period_given(calculator)
    t('supply_teachers.home.temp_to_perm_fee.notice_period_given',
      days: calculator.days_notice_given,
      notice_date: calculator.notice_date.to_s(:long_with_day),
      hire_date: calculator.hire_date.to_s(:long_with_day))
  end

  def display_chargeable_days_for_lack_of_notice(calculator)
    t('supply_teachers.home.temp_to_perm_fee.lack_of_notice_chargeable_days',
      days: calculator.chargeable_working_days_based_on_lack_of_notice)
  end

  def display_suppliers_daily_fee(calculator)
    t('supply_teachers.home.temp_to_perm_fee.daily_supplier_fee',
      fee: number_to_currency(calculator.daily_supplier_fee),
      markup_rate: number_to_percentage(calculator.markup_rate * 100, precision: 1),
      day_rate: number_to_currency(calculator.day_rate))
  end
end
