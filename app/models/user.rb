class User < ApplicationRecord
  include RoleModel

  has_many  :procurements,
            inverse_of: :user,
            class_name: 'FacilitiesManagement::Procurement',
            dependent: :destroy

  has_one :buyer_detail,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::BuyerDetail',
          dependent: :destroy

  has_one :supplier_detail,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::SupplierDetail',
          dependent: :destroy

  has_one :supplier_admin,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::Admin::SuppliersAdmin',
          dependent: :destroy

  has_many :buildings,
           class_name: 'FacilitiesManagement::Building',
           inverse_of: :user,
           dependent: :destroy

  has_many :management_reports,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::Admin::ManagementReport',
           dependent: :nullify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :trackable and :omniauthable
  devise :registerable, :recoverable, :timeoutable

  def authenticatable_salt
    "#{id}#{session_token}"
  end

  def invalidate_session!
    self.session_token = SecureRandom.hex
  end

  roles_attribute :roles_mask

  # declare the valid roles -- do not change the order if you add more
  # roles later, always append them at the end!
  roles :buyer, :supplier, :ccs_employee, :ccs_admin, :st_access, :fm_access, :ls_access, :mc_access

  attr_accessor :password, :password_confirmation

  def confirmed?
    confirmed_at.present?
  end

  def fm_buyer_details_incomplete?
    # used to assist the site in determining if the user
    # is a buyer and if they are required to complete information in
    # the buyer-account details page

    if has_role? :buyer
      !(buyer_detail.present? && buyer_detail&.valid?(:update) && buyer_detail&.valid?(:update_address))
    else
      false
    end
  end
end
