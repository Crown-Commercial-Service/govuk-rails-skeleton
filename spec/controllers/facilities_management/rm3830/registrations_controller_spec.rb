require 'rails_helper'

RSpec.describe FacilitiesManagement::RM3830::RegistrationsController, type: :controller do
  let(:default_params) { { service: 'facilities_management', framework: 'RM3830' } }

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET new' do
    before { get :new }

    it 'renders the new page' do
      expect(response).to render_template(:new)
    end

    it 'gives the user the buyer and fm_access roles' do
      expect(assigns(:result).roles).to eq(%i[buyer fm_access])
    end
  end

  describe 'POST create' do
    let(:email) { 'test@testemail.com' }
    let(:password) { 'Password890!' }
    let(:password_confirmation) { password }

    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Cognito::SignUpUser).to receive(:create_cognito_user).and_return({ 'user_sub': '1234567890' })
      allow_any_instance_of(Cognito::SignUpUser).to receive(:add_user_to_groups).and_return(true)
      allow_any_instance_of(AllowedEmailDomain).to receive(:allow_list).and_return(['testemail.com'])
      # rubocop:enable RSpec/AnyInstance
      post :create, params: { user: { email: email, password: password, password_confirmation: password_confirmation } }
      cookies.update(response.cookies)
    end

    context 'when the emaildomain is not on the allow list' do
      let(:email) { 'test@fake-testemail.com' }

      it 'redirects to facilities_management_rm3830_domain_not_on_safelist_path' do
        expect(response).to redirect_to facilities_management_rm3830_domain_not_on_safelist_path
      end
    end

    context 'when some of the information is invalid' do
      let(:password_confirmation) { 'I do not match the password' }

      it 'renders the new page' do
        expect(response).to render_template(:new)
      end
    end

    context 'when all the information is valid' do
      it 'redirects to facilities_management_rm3830_users_confirm_path' do
        expect(response).to redirect_to facilities_management_rm3830_users_confirm_path
      end

      it 'sets the crown_marketplace_confirmation_email cookie' do
        expect(cookies[:crown_marketplace_confirmation_email]).to eq email
      end
    end
  end

  describe 'GET domain_not_on_safelist' do
    before { get :domain_not_on_safelist }

    it 'renders the new page' do
      expect(response).to render_template(:domain_not_on_safelist)
    end
  end
end
