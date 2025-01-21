module FacilitiesManagement::RM3830::Admin::SupplierRatesHelper
  def self.add_rates_to_work_packages(work_packages, rates)
    work_packages.map do |work_package|
      work_package['rates'] = rates.select { |key| key['code'] == work_package['code'] }
      work_package['rate_standard_a_or_blank'] = work_package['rates'].select { |rate| rate['standard'] == 'A' || rate['standard'].blank? }.first
      work_package
    end
  end

  def self.work_package_to_services(services, work_packages)
    full_services = []

    services.each do |service|
      service['work_package'] = work_packages.select { |key| key['work_package_code'] == service['code'] }

      standards = service['work_package'].map { |package| package['rates'].map(&:standard) }.flatten.uniq.compact

      service['standard_a'] = standards.include? 'A'
      service['standard_b'] = standards.include? 'B'
      service['standard_c'] = standards.include? 'C'

      service['value_type'] = ['M', 'N'].include?(service['code']) ? 'percentage' : 'money'

      full_services.push(service)
    end
  end
end
