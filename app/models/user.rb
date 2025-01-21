class User < ApplicationRecord
  include RoleModel

  has_many :rm3830_procurements,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM3830::Procurement',
           dependent: :destroy

  has_many :rm6232_procurements,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM6232::Procurement',
           dependent: :destroy

  has_one :buyer_detail,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::BuyerDetail',
          dependent: :destroy

  has_one :supplier_detail,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::RM3830::SupplierDetail',
          dependent: :destroy

  has_one :supplier_admin,
          inverse_of: :user,
          class_name: 'FacilitiesManagement::RM3830::Admin::SuppliersAdmin',
          dependent: :destroy

  has_many :buildings,
           class_name: 'FacilitiesManagement::Building',
           inverse_of: :user,
           dependent: :destroy

  has_many :rm3830_management_reports,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM3830::Admin::ManagementReport',
           dependent: :nullify

  has_many :rm6232_management_reports,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM6232::Admin::ManagementReport',
           dependent: :nullify

  has_many :rm3830_admin_uploads,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM3830::Admin::Upload',
           dependent: :nullify

  has_many :rm6232_admin_uploads,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM6232::Admin::Upload',
           dependent: :nullify

  has_many :rm6232_supplier_data_edits,
           inverse_of: :user,
           class_name: 'FacilitiesManagement::RM6232::Admin::SupplierData::Edit',
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
  roles :buyer, :supplier, :ccs_employee, :ccs_admin, :st_access, :fm_access, :ls_access, :mc_access, :allow_list_access, :ccs_developer, :ccs_user_admin

  attr_accessor :password, :password_confirmation

  def confirmed?
    confirmed_at.present?
  end

  def fm_buyer_details_incomplete?
    # used to assist the site in determining if the user
    # is a buyer and if they are required to complete information in
    # the buyer-account details page

    if has_role? :buyer
      !(buyer_detail.present? && buyer_detail&.valid?(:update) && buyer_detail.valid?(:update_address))
    else
      false
    end
  end
end
