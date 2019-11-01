module FacilitiesManagement::Beta::ProcurementBuildingsHelper
  def service_questions(code)
    FacilitiesManagement::ProcurementBuildingService::SERVICES_AND_QUESTIONS.select { |service| service[:code] == code }.first
  end

  def volume_question(code)
    service_questions(code)[:questions].first
  end

  def ppm_standard_question(code)
    service_questions(code)[:questions].last
  end

  def question_type(service, question)
    if question == :service_standard
      'ppm_standards' if service.requires_ppm_standards?
    elsif service.requires_volume?
      'volume'
    end
  end

  def checked?(object_value, value)
    object_value == value
  end
end
