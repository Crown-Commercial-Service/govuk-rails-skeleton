module FacilitiesManagement
  module RM3830
    module Admin
      class SessionsController < Base::SessionsController
        protected

        def service_challenge_path
          facilities_management_rm3830_admin_users_challenge_path(challenge_name: @result.challenge_name)
        end

        # rubocop:disable Lint/UnusedMethodArgument
        def after_sign_in_path_for(resource)
          # keep these lines for the moment, to remind us to use the logic as when a regular user signs in
          #  return edit_facilities_management_buyer_detail_path(FacilitiesManagement::BuyerDetail.find_or_create_by(user: current_user)) if current_user.fm_buyer_details_incomplete?

          # stored_location_for(resource) || facilities_management_path
          facilities_management_rm3830_admin_path
        end
        # rubocop:enable Lint/UnusedMethodArgument

        def after_sign_out_path_for(_resource)
          facilities_management_rm3830_admin_new_user_session_path
        end

        def new_session_path
          facilities_management_rm3830_admin_new_user_session_path
        end

        def confirm_forgot_password_path
          facilities_management_rm3830_admin_edit_user_password_path
        end

        def confirm_email_path
          facilities_management_rm3830_admin_users_confirm_path
        end
      end
    end
  end
end
