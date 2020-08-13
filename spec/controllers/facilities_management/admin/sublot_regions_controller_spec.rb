require 'rails_helper'

RSpec.describe FacilitiesManagement::Admin::SublotRegionsController do
  login_fm_admin
  supplier_id = 'ca57bf4c-e8a5-468a-95f4-39fcf730c567'
  lot_data = {
    '1a':
    {
      'regions': [
        'UKC1',
        'UKC2',
        'UKD1',
      ],
      'services': [
        'A.7',
        'A.12',
      ]
    },
    '1b':
    {
      'regions': [
        'UKC1',
        'UKC2'
      ],
      'services': [
        'A.7',
        'A.12'
      ]
    },
    '1c':
    {
      'regions': [
        'UKC1',
        'UKC2'
      ],
      'services': [
        'A.7',
        'A.12'
      ]
    }
  }

  contact_name = 'Doreatha Tunnell'
  contact_email = 'rowe-hessel-and-heller@yopmail.com'
  contact_phone = '01482 133573'
  supplier_name = 'Rowe, Hessel and Heller'

  before do
    FacilitiesManagement::Admin::SuppliersAdmin.where(supplier_id: supplier_id).first_or_create(supplier_id: supplier_id, contact_name: contact_name, contact_email: contact_email, contact_phone: contact_phone, supplier_name: supplier_name, lot_data: lot_data, created_at: 'now()')
  end

  describe 'GET and PUT sublot_regions controller' do
    context 'when sublot_region 1a page is rendered' do
      it 'returns http success' do
        get :sublot_region, params: { id: supplier_id, lot_type: '1a' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when sublot_region 1b page is rendered' do
      it 'returns http success' do
        get :sublot_region, params: { id: supplier_id, lot_type: '1b' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when sublot_region 1c page is rendered' do
      it 'returns http success' do
        get :sublot_region, params: { id: supplier_id, lot_type: '1c' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when sublot_region does not exist redirect to admin home page' do
      it 'returns http success' do
        get :sublot_region, params: { id: supplier_id, lot_type: '1e' }
        expect(response).to redirect_to facilities_management_admin_path
      end
    end

    context 'when update sublot_regions' do
      context 'when there are regions' do
        let(:regions) { ['UKC1', 'UKC2'] }

        before do
          put :update_sublot_regions, params: { id: supplier_id, lot_type: '1a', regions: regions }
        end

        it 'returns http success' do
          expect(response).to redirect_to facilities_management_admin_supplier_framework_data_path
        end

        it 'updates the regions correctly' do
          expect(FacilitiesManagement::Admin::SuppliersAdmin.find(supplier_id).lot_data['1a']['regions']).to eq regions
        end
      end

      context 'when there are no regions' do
        before do
          put :update_sublot_regions, params: { id: supplier_id, lot_type: '1a' }
        end

        it 'returns http success' do
          expect(response).to redirect_to facilities_management_admin_supplier_framework_data_path
        end

        it 'updates the regions correctly' do
          expect(FacilitiesManagement::Admin::SuppliersAdmin.find(supplier_id).lot_data['1a']['regions']).to eq []
        end
      end
    end

    context 'when not an fm admin' do
      login_fm_buyer_with_details

      it 'redirects to not permitted page' do
        get :sublot_region, params: { id: supplier_id, lot_type: '1a' }
        expect(response).to redirect_to not_permitted_path(service: 'facilities_management')
      end
    end
  end
end
