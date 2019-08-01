module ManagementConsultancy
  class UsersController < Base::UsersController
    private

    def new_challenge_path
      management_consultancy_users_challenge_path(challenge_name: @challenge.new_challenge_name, session: @challenge.new_session, username: params[:username])
    end

    def after_sign_in_path_for(resource)
      stored_location_for(resource) || management_consultancy_journey_start_path
    end

    def confirm_user_registration_path
      management_consultancy_users_confirm_path(email: params[:email])
    end
  end
end
