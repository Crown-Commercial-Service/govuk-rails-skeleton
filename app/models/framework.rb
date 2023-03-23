class Framework < ApplicationRecord
  scope :facilities_management, -> { where(service: 'facilities_management').order(live_at: :asc) }

  acts_as_gov_uk_date :live_at, :expires_at, error_clash_behaviour: :omit_gov_uk_date_field_error

  validate :dates_are_valid, on: :update

  def self.frameworks
    pluck(:framework)
  end

  def self.live_frameworks
    where('live_at <= ? AND expires_at > ?', Time.now.in_time_zone('London'), Time.now.in_time_zone('London')).pluck(:framework)
  end

  def self.current_framework
    live_frameworks.last
  end

  def self.live_framework?(framework)
    live_frameworks.include?(framework)
  end

  def self.recognised_framework?(framework)
    frameworks.include?(framework)
  end

  def status
    if self.class.send(service).live_framework?(framework)
      :live
    else
      live_at <= Time.now.in_time_zone('London') ? :expired : :coming
    end
  end

  private

  def dates_are_valid
    date_present(:live_at)
    date_present(:expires_at)
    date_real(:live_at)
    date_real(:expires_at)

    validate_expires_at_after_live_at if errors.none?
  end

  def date_present(attribute)
    errors.add(attribute, :blank) if send("#{attribute}_yyyy").blank? || send("#{attribute}_mm").blank? || send("#{attribute}_dd").blank?
  end

  def date_real(attribute)
    errors.add(attribute, :not_a_date) unless Date.valid_date?(send("#{attribute}_yyyy").to_i, send("#{attribute}_mm").to_i, send("#{attribute}_dd").to_i)
  end

  def validate_expires_at_after_live_at
    errors.add(:expires_at, :not_after_live_at_date) unless expires_at > live_at
  end
end
