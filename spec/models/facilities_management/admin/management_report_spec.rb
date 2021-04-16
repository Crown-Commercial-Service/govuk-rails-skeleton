require 'rails_helper'

RSpec.describe FacilitiesManagement::Admin::ManagementReport, type: :model do
  subject(:management_report) { build(:facilities_management_admin_management_report, user: user) }

  let(:user) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }

    context 'when the start date is invalid' do
      before do
        management_report.start_date_dd = '88'
        management_report.start_date_mm = '8'
        management_report.start_date_yyyy = '2020'

        management_report.save
      end

      it 'verifies that the start date is a valid date' do
        expect(management_report.errors.details[:start_date].first[:error]).to eq(:not_a_date)
      end

      it 'has the correct error message' do
        expect(management_report.errors[:start_date].first).to eq 'Enter a valid ‘From’ date'
      end
    end

    context 'when the end date is invalid' do
      before do
        management_report.end_date_dd = '88'
        management_report.end_date_mm = '8'
        management_report.end_date_yyyy = '2020'

        management_report.save
      end

      it 'verifies that the end date is a valid date' do
        expect(management_report.errors.details[:end_date].first[:error]).to eq(:not_a_date)
      end

      it 'has the correct error message' do
        expect(management_report.errors[:end_date].first).to eq 'Enter a valid ‘To’ date'
      end
    end

    context 'when the start date is in the past' do
      before do
        management_report.start_date = Time.zone.today + 1.day

        management_report.save
      end

      it 'verifies that the start date is date in the past' do
        expect(management_report.errors.details[:start_date].first[:error]).to eq(:date_before_or_equal_to)
      end

      it 'has the correct error message' do
        expect(management_report.errors[:start_date].first).to eq 'The ‘From’ date must be today or in the past'
      end
    end

    context 'when the end date is in the past' do
      before do
        management_report.end_date = Time.zone.today + 1.day

        management_report.save
      end

      it 'verifies that the end date is date in the past' do
        expect(management_report.errors.details[:end_date].first[:error]).to eq(:date_before_or_equal_to)
      end

      it 'has the correct error message' do
        expect(management_report.errors[:end_date].first).to eq 'The ‘To’ date must be today or in the past'
      end
    end

    context 'when the start date is before or equal to the end date' do
      before do
        management_report.start_date = Time.zone.today
        management_report.end_date = Time.zone.today - 1.day

        management_report.save
      end

      it 'is not valid' do
        expect(management_report.errors.details[:end_date].first[:error]).to eq(:must_be_before_start_date)
      end

      it 'has the correct error message' do
        expect(management_report.errors[:end_date].first).to eq 'The ‘To’ date must be the same or after the ‘From’ date'
      end
    end

    context 'when the start date is equal to the end date' do
      before do
        management_report.start_date = Time.zone.today
        management_report.end_date = Time.zone.today
      end

      it 'is valid' do
        expect(management_report.valid?).to eq(true)
      end
    end
  end
end
