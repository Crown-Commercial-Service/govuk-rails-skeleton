module SupplyTeachers
  module Journey::Results
    extend ActiveSupport::Concern
    include BranchesHelper
    include Geolocatable

    def branches(daily_rates = {})
      point = location.point
      Branch.search(point, rates: rates, radius: radius).map do |branch|
        search_result_for(branch).tap do |result|
          result.rate = rate(branch)
          result.distance = point.distance(branch.location)
          result.daily_rate = daily_rates.fetch(branch.id, nil)
          result.worker_cost = supplier_mark_up(result.daily_rate, result.rate)&.worker_cost
          result.agency_fee = supplier_mark_up(result.daily_rate, result.rate)&.agency_fee
          result.fixed_term_length = supplier_finders_fee(result.fixed_term_length, result.rate)&.fixed_term_length
          result.finders_fee = supplier_finders_fee(result.fixed_term_length, result.rate)&.finders_fee
        end
      end
    end

    def search_result_for(branch)
      BranchSearchResult.new(
        id: branch.id,
        supplier_name: branch.supplier.name,
        name: display_name_for_branch(branch),
        contact_name: branch.contact_name,
        telephone_number: branch.telephone_number,
        contact_email: branch.contact_email,
        slug: branch.slug
      )
    end

    private

    def supplier_mark_up(daily_rate, markup_rate)
      return unless daily_rate && markup_rate
      return if daily_rate.empty?

      SupplierMarkUp.new(daily_rate: daily_rate, markup_rate: markup_rate)
    end

    def supplier_finders_fee(fixed_term_length, rate)
      return unless fixed_term_length && rate
      return if fixed_term_length.empty?

      SupplierMarkUp.new(fixed_term_length: fixed_term_length, rate: rate)
    end
  end
end
