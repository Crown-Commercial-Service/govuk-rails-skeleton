require 'rails_helper'

RSpec.describe 'layouts/application.html.erb' do
  let(:support_link_feedback_address) { 'https://www.smartsurvey.co.uk/s/J1VQQI/' }

  before do
    allow(view).to receive_messages(user_signed_in?: false, ccs_homepage_url: 'https://CCSHOMEPAGE', service_path_base: '/supply-teachers')

    cookies[:cookie_preferences_cmp] = {
      value: {
        'settings_viewed' => true,
        'usage' => true,
        'glassbox' => true
      }.to_json
    }

    allow(cookies.class).to receive(:new).and_return(cookies)
    allow(Marketplace).to receive_messages(google_tag_manager_tracking_id: '456', fm_survey_link: support_link_feedback_address)
  end

  describe 'feedback links' do
    let(:support_link_selector) do
      %(a[href="#{support_form_link}"])
    end

    let(:feedback_link_selector) do
      %(a[href="#{support_link_feedback_address}"])
    end

    context 'when feedback email address is present' do
      let(:feedback_email_address) { 'feedback@something.com' }
      let(:support_form_link) { 'https://www.crowncommercial.gov.uk/contact' }

      it 'displays link to feedback email address in beta banner' do
        render

        expect(rendered).to have_css(".govuk-phase-banner #{feedback_link_selector}")
      end

      it 'displays link to support email address above footer' do
        render

        expect(rendered).to have_css(".ccs-contact-us #{support_link_selector}")
      end
    end
  end

  it 'includes google tag manager partials' do
    stub_template 'shared/google/_tag_manager_body.html.erb' => 'GTM BODY'
    stub_template 'shared/google/_tag_manager_head.html.erb' => 'GTM HEAD'
    render
    expect(rendered).to match(/GTM BODY/)
    expect(rendered).to match(/GTM HEAD/)
  end

  it 'renders the page title stored in the locale file' do
    render
    expected = t('layouts.application.title')
    expect(rendered).to have_css('title', text: expected, visible: :hidden)
  end

  it 'adds an optional prefix to the page title' do
    view.content_for(:page_title_prefix) { 'Prefix' }
    render
    expected = "Prefix: #{t('layouts.application.title')}"
    expect(rendered).to have_css('title', text: expected, visible: :hidden)
  end
end
