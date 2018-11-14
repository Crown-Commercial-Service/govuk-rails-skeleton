require 'rails_helper'

RSpec.describe 'journey/agency_payroll.html.erb' do
  let(:step) { SupplyTeachers::Steps::AgencyPayroll.new }
  let(:errors) { ActiveModel::Errors.new(step) }
  let(:journey) { instance_double('Journey', errors: errors, params: params) }

  before do
    view.extend(ApplicationHelper)
    assign(:journey, journey)
    assign(:form_path, '/')
  end

  context 'when there are previous questions/answers stored in the params' do
    before do
      params[:question] = 'answer'
    end

    it 'stores them in hidden fields' do
      render
      expect(rendered).to have_css('input[type="hidden"][name="question"][value="answer"]', visible: false)
    end
  end

  context 'when the current questions/answers are stored in the params' do
    before do
      params[:postcode] = 'postcode'
      params[:job_type] = 'job-type'
      params[:term] = 'term'
    end

    it 'does not store the postcode answer in a hidden field' do
      render
      expect(rendered).not_to have_css('input[type="hidden"][name="postcode"]', visible: false)
    end

    it 'does not store the job_type answer in a hidden field' do
      expect(rendered).not_to have_css('input[type="hidden"][name="job_type"]', visible: false)
    end

    it 'does not store the term answer in a hidden field' do
      expect(rendered).not_to have_css('input[type="hidden"][name="term"]', visible: false)
    end
  end

  it 'does not display the error summary' do
    render
    expect(rendered).not_to have_css('.govuk-error-summary')
  end

  it 'does not include any error message classes' do
    render
    expect(rendered).not_to have_css('.govuk-form-group--error')
    expect(rendered).not_to have_css('.govuk-error-message')
    expect(rendered).not_to have_css('.govuk-input--error')
  end

  it 'does not set the page title prefix' do
    render
    expect(view.content_for(:page_title_prefix)).to be_nil
  end

  context 'when the journey has an error' do
    before do
      errors.add(:location, 'error-message')
      render
    end

    it 'displays the error summary' do
      expect(rendered).to have_css('.govuk-error-summary')
    end

    it 'adds the form group error class' do
      expect(rendered).to have_css('.govuk-form-group.govuk-form-group--error')
    end

    it 'adds the message to the field with the error' do
      expect(rendered).to have_css('#location-error.govuk-error-message', text: 'error-message')
    end

    it 'adds the error class to the postcode input' do
      expect(rendered).to have_css('input[name=postcode][type=text].govuk-input--error')
    end

    it 'adds an error prefix to the page title' do
      render
      expect(view.content_for(:page_title_prefix)).to match(t('layouts.application.error_prefix'))
    end
  end
end
