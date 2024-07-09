module FacilitiesManagement
  module RM6232
    module Admin
      class SupplierData::Snapshot
        include ActiveModel::Model

        attr_accessor :snapshot_date_time, :snapshot_date, :snapshot_time,
                      :snapshot_date_yyyy, :snapshot_date_mm, :snapshot_date_dd, :snapshot_time_hh, :snapshot_time_mm

        validate :snapshot_date_present, :snapshot_date_real, :snapshot_time_real, :supplier_data_present

        def initialize(attributes = {})
          super
          create_snapshot_date_time
        end

        def generate_snapshot_zip
          snapshot_generator = SupplierDataSnapshotGenerator.new(snapshot_date_time)
          snapshot_generator.build_zip_file
          snapshot_generator.to_zip
        end

        def snapshot_filename
          "Supplier data spreadsheets (#{snapshot_date_time.in_time_zone('London').strftime(format_time_string).squish}).zip"
        end

        private

        def create_snapshot_date_time
          self.snapshot_date_time = if snapshot_time_blank?
                                      Time.find_zone('London').local(*date_parameters).in_time_zone('UTC').end_of_day
                                    else
                                      Time.find_zone('London').local(*date_parameters, snapshot_time_hh.to_i, snapshot_time_mm.to_i).in_time_zone('UTC')
                                    end
        rescue ArgumentError
          # We can do nothing and leave snapshot_date_time as nil
        end

        def snapshot_date_present
          errors.add(:snapshot_date, :blank) if snapshot_date_yyyy.blank? || snapshot_date_mm.blank? || snapshot_date_dd.blank?
        end

        def snapshot_date_real
          errors.add(:snapshot_date, :not_a_date) unless Date.valid_date?(*date_parameters)
        end

        def snapshot_time_real
          return if snapshot_time_blank?

          if snapshot_time_integers?
            hours = snapshot_time_hh.to_i
            minutes = snapshot_time_mm.to_i

            return unless hours > 23 || hours.negative? || minutes > 59 || minutes.negative?
          end

          errors.add(:snapshot_time, :not_a_time)
        end

        def supplier_data_present
          return if errors.any?

          errors.add(:snapshot_date_time, :no_supplier_data, oldest_data_created_at: SupplierData.oldest_data_created_at_string) if snapshot_date_time + 1.minute < SupplierData.oldest_data_created_at
        end

        def snapshot_time_blank?
          snapshot_time_hh.blank? && snapshot_time_mm.blank?
        end

        def snapshot_time_integers?
          snapshot_time_hh&.match?(INTEGER_REGEX) && snapshot_time_mm&.match?(INTEGER_REGEX)
        end

        def date_parameters
          [snapshot_date_yyyy.to_i, snapshot_date_mm.to_i, snapshot_date_dd.to_i]
        end

        def format_time_string
          snapshot_time_blank? ? '%d_%m_%Y' : '%d_%m_%Y %H_%M'
        end

        INTEGER_REGEX = /\A[+-]?\d+\z/
      end
    end
  end
end
