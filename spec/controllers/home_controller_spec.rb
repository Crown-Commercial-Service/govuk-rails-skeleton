require 'rails_helper'

RSpec.describe HomeController do
  describe 'GET index' do
    it 'redirects to the CCS home page' do
      get :index

      expect(response).to redirect_to('https://www.crowncommercial.gov.uk/')
    end
  end

  describe 'GET healthcheck' do
    it 'displays status information about the app' do
      get :healthcheck

      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response.parsed_body).to eq(
        {
          'status' => 'ok',
          'git_commit' => 'expected-git-commit'
        }
      )
    end
  end
end
