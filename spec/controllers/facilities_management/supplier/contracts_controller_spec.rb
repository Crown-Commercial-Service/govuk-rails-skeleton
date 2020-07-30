require 'rails_helper'

RSpec.describe FacilitiesManagement::Supplier::ContractsController, type: :controller do
  describe 'PUT update' do
    let(:user) { FactoryBot.create(:user, :with_detail, confirmed_at: Time.zone.now, roles: %i[supplier fm_access]) }
    let(:procurement) { create(:facilities_management_procurement_with_contact_details, user: user) }
    let(:contract) { create(:facilities_management_procurement_supplier_da_with_supplier, facilities_management_procurement_id: procurement.id, aasm_state: 'sent', offer_sent_date: Time.zone.now) }
    let(:supplier) { CCS::FM::Supplier.all.first }

    ENV['RAILS_ENV_URL'] = 'https://test-fm'
    login_fm_supplier

    before do
      supplier.data['contact_email'] = controller.current_user.email
      allow(CCS::FM::Supplier).to receive(:find).and_return(supplier)
    end

    context 'when the supplier accepts the procurement' do
      before do
        put :update, params: { procurement_id: procurement.id, id: contract.id, facilities_management_procurement_supplier: { contract_response: true } }
      end

      it 'redirects to facilities_management_supplier_contract_sent_index_path' do
        expect(response).to redirect_to facilities_management_supplier_contract_sent_index_path(contract.id)
      end

      it 'updates the state of the contract to accepted' do
        contract.reload

        expect(contract.accepted?).to be true
      end
    end

    context 'when the supplier declines the procurement' do
      context 'when supplier adds a valid reason' do
        let(:reason_for_declining) { 'Can not provide the service' }

        before do
          put :update, params: { procurement_id: procurement.id, id: contract.id, facilities_management_procurement_supplier: { contract_response: false, reason_for_declining: reason_for_declining } }
        end

        it 'redirects to facilities_management_supplier_contract_sent_index_path' do
          expect(response).to redirect_to facilities_management_supplier_contract_sent_index_path(contract.id)
        end

        it 'updates the state of the contract to declined' do
          contract.reload

          expect(contract.declined?).to be true
        end

        it 'updates the reason for declining' do
          contract.reload

          expect(contract.reason_for_declining).to eq reason_for_declining
        end
      end

      context 'when the supplier does not add a valid reason' do
        it 'renders the edit template' do
          put :update, params: { procurement_id: procurement.id, id: contract.id, facilities_management_procurement_supplier: { contract_response: false, reason_for_declining: '' } }

          expect(response).to render_template('edit')
        end
      end
    end
  end

  describe '.authorize_user' do
    let(:contract) { create(:facilities_management_procurement_supplier) }
    let(:procurement) { create(:facilities_management_procurement, user: user) }
    let(:user) { FactoryBot.create(:user, :without_detail, confirmed_at: Time.zone.now, roles: %i[supplier fm_access]) }
    let(:wrong_user) { FactoryBot.create(:user, :without_detail, confirmed_at: Time.zone.now, roles: %i[supplier fm_access]) }
    let(:supplier) { CCS::FM::Supplier.all.first }

    before do
      supplier.data['contact_email'] = user.email
      allow(CCS::FM::Supplier).to receive(:find).and_return(supplier)
    end

    context 'when the user is not the intended supplier' do
      before { sign_in wrong_user }

      it 'will not be able to manage the contract' do
        ability = Ability.new(wrong_user)
        assert ability.cannot?(:manage, contract)
      end

      it 'redirects to the not permited page' do
        get :show, params: { procurement_id: procurement.id, id: contract.id }

        expect(response).to redirect_to not_permitted_url(service: 'facilities_management')
      end
    end

    context 'when the user is the intended supplier' do
      before { sign_in user }

      it 'will be able to manage the contract' do
        ability = Ability.new(user)
        assert ability.can?(:manage, contract)
      end

      it 'renders the show page' do
        get :show, params: { procurement_id: procurement.id, id: contract.id }

        expect(response).to render_template('show')
      end
    end
  end
end
