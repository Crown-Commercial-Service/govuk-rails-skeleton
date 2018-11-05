require 'rails_helper'

RSpec.describe FacilitiesManagementWorkPackage, type: :model do
  subject(:packages) { described_class.all }

  let(:first_package) { packages.first }

  it 'loads work packages from CSV' do
    expect(packages.count).to eq(15)
  end

  it 'populates attributes of first work package' do
    expect(first_package.code).to eq('A')
    expect(first_package.name).to eq('Contract Management')
  end
end
