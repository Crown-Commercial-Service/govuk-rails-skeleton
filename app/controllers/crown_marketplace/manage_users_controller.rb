class CrownMarketplace::ManageUsersController < CrownMarketplace::FrameworkController
  before_action :authorize_user, :set_current_user_access
  before_action :redirect_if_unrecognised_add_user_section, :continue_if_user_support, only: %i[add_user create_add_user]
  before_action :continue_if_role_does_not_require_service_access, only: :add_user
  before_action :set_new_user, only: %i[add_user new]
  before_action :set_user, only: %i[show edit update resend_temporary_password]
  before_action :redirect_if_lack_permissions, only: %i[edit update resend_temporary_password]
  before_action :redirect_if_unpermitted_section, only: %i[edit update]

  helper_method :section, :available_roles, :role_requires_service_access?, :can_edit_user?, :permitted_sections

  def index
    @search = if find_user_params.empty?
                { users: [] }
              else
                Cognito::Admin::User.search(find_user_params[:email])
              end

    respond_to do |format|
      format.js
      format.html { render :index }
    end
  end

  def add_user; end

  def create_add_user
    @user = Cognito::Admin::User.new(@current_user_access, add_user_params)

    if @user.valid?(section)
      next_section = ADD_USER_SECTIONS[ADD_USER_SECTIONS.index(section) + 1]

      if next_section
        redirect_to add_user_crown_marketplace_manage_users_path(section: next_section.to_s.dasherize, **add_user_params.to_h)
      else
        redirect_to new_crown_marketplace_manage_user_path(**add_user_params.to_h)
      end
    else
      render :add_user
    end
  end

  def show
    @minimum_editor = @user.minimum_editor_role
  end

  def new; end

  def edit; end

  def create
    @user = Cognito::Admin::User.new(@current_user_access, add_user_params)

    if @user.create
      flash[:account_added] = @user.email

      redirect_to crown_marketplace_path
    else
      render :new
    end
  end

  def update
    @user.assign_attributes(**user_params)

    if @user.update(section)
      redirect_to crown_marketplace_manage_user_path
    else
      render :edit
    end
  end

  def resend_temporary_password
    error = @user.resend_temporary_password

    if error
      flash[:error_message] = error
    else
      flash[:password_resent] = @user.email
    end

    redirect_to crown_marketplace_manage_user_path
  end

  private

  def section
    @section ||= params[:section]&.underscore&.to_sym
  end

  def available_roles
    @available_roles ||= @user&.cognito_roles&.available_roles || Cognito::Admin::Roles.find_available_roles(@current_user_access)
  end

  def role_requires_service_access?(roles)
    [['buyer'], ['ccs_employee']].include?(roles)
  end

  def can_edit_user?
    @can_edit_user ||= @user.can_edit_user_with_current_access?
  end

  def redirect_if_unrecognised_add_user_section
    redirect_to crown_marketplace_path unless ADD_USER_SECTIONS.include?(section)
  end

  def continue_if_user_support
    redirect_to add_user_crown_marketplace_manage_users_path(section: 'select-service-access', roles: ['buyer']) if section == :select_role && @current_user_access == :user_support
  end

  def continue_if_role_does_not_require_service_access
    return unless section == :select_service_access && !role_requires_service_access?(params[:roles])

    redirect_to add_user_crown_marketplace_manage_users_path(section: 'enter-user-details', **filter_user_params)
  end

  def redirect_if_lack_permissions
    return if can_edit_user?

    flash[:error_message] = I18n.t('crown_marketplace.home.index.lack_permissions')
    redirect_to crown_marketplace_path
  end

  def redirect_if_unpermitted_section
    redirect_to crown_marketplace_manage_user_path unless permitted_sections.include? section
  end

  def add_user_params
    if params[:cognito_admin_user]
      params.require(:cognito_admin_user).permit(ADD_USER_PERMITTED_PARAMS)
    else
      {}
    end
  end

  def find_user_params
    @find_user_params ||= params.permit(:email)
  end

  def user_params
    if params[:cognito_admin_user]
      params.require(:cognito_admin_user).permit(PERMITED_PARAMS[section])
    else
      case section
      when :roles, :service_access
        { section => [] }
      else
        {}
      end
    end
  end

  def permitted_sections
    @permitted_sections ||= if @current_user_access == :user_support
                              USER_SUPPORT_EDIT_SECTIONS
                            else
                              RECOGNISED_EDIT_SECTIONS
                            end
  end

  def authorize_user
    authorize! :read, AllowedEmailDomain
  end

  def set_current_user_access
    @current_user_access = Cognito::Admin::Roles.current_user_access(current_ability)
  end

  def set_new_user
    @user = Cognito::Admin::User.new(@current_user_access, filter_user_params)
  end

  def set_user
    @user = Cognito::Admin::User.find(@current_user_access, params[:cognito_uuid])

    return unless @user.error

    flash[:error_message] = @user.error
    redirect_to crown_marketplace_path
  end

  def filter_user_params
    {
      roles: params[:roles],
      service_access: params[:service_access],
      email: params[:email],
      telephone_number: params[:telephone_number]
    }.compact_blank
  end

  ADD_USER_SECTIONS = %i[select_role select_service_access enter_user_details].freeze
  ADD_USER_PERMITTED_PARAMS = [
    :email,
    :telephone_number,
    { roles: [] },
    { service_access: [] }
  ].freeze

  USER_SUPPORT_EDIT_SECTIONS = %i[email_verified account_status service_access].freeze
  RECOGNISED_EDIT_SECTIONS = (USER_SUPPORT_EDIT_SECTIONS + %i[telephone_number mfa_enabled roles]).freeze
  PERMITED_PARAMS = {
    email_verified: %i[email_verified],
    account_status: %i[account_status],
    telephone_number: %i[telephone_number],
    mfa_enabled: %i[mfa_enabled],
    roles: {
      roles: []
    },
    service_access: {
      service_access: []
    }
  }.freeze
end
