require 'rails_helper'

RSpec.describe FacilitiesManagement::RM6232::ProcurementDetailsHelper, type: :helper do
  describe '.edit_page_title' do
    let(:result) { helper.edit_page_title }

    before { allow(helper).to receive(:section).and_return(section) }

    context 'when the section is contract_name' do
      let(:section) { :contract_name }

      it 'returns Contract name' do
        expect(result).to eq('Contract name')
      end
    end

    context 'when the section is annual_contract_value' do
      let(:section) { :annual_contract_value }

      it 'returns Annual contract value' do
        expect(result).to eq('Annual contract value')
      end
    end

    context 'when the section is tupe' do
      let(:section) { :tupe }

      it 'returns Tupe' do
        expect(result).to eq('TUPE')
      end
    end

    context 'when the section is contract_period' do
      let(:section) { :contract_period }

      it 'returns Contract period' do
        expect(result).to eq('Contract period')
      end
    end

    context 'when the section is services' do
      let(:section) { :services }

      it 'returns Services' do
        expect(result).to eq('Services')
      end
    end

    context 'when the section is buildings' do
      let(:section) { :buildings }

      it 'returns Buildings' do
        expect(result).to eq('Buildings')
      end
    end
  end

  describe '.show_page_title' do
    let(:result) { helper.show_page_title }

    before { allow(helper).to receive(:section).and_return(section) }

    context 'when the section is contract_period' do
      let(:section) { :contract_period }

      it 'returns Contract period summary' do
        expect(result).to eq('Contract period summary')
      end
    end

    context 'when the section is services' do
      let(:section) { :services }

      it 'returns Services summary' do
        expect(result).to eq('Services summary')
      end
    end

    context 'when the section is buildings' do
      let(:section) { :buildings }

      it 'returns Buildings summary' do
        expect(result).to eq('Buildings summary')
      end
    end

    context 'when the section is buildings_and_services' do
      let(:section) { :buildings_and_services }

      it 'returns Assigning services to buildings summary' do
        expect(result).to eq('Assigning services to buildings summary')
      end
    end
  end
end
