module Droom::Users
  class PasswordsController < Devise::PasswordsController
    respond_to :html, :json
    before_filter :set_access_control_headers
    skip_before_filter :require_no_authentication, only: [:completed]
    before_filter :remember_original_destination, only: [:new]

    def show
      render
    end

    def completed
      render
    end

    def after_resetting_password_path_for(resource)
      droom.complete_confirmation_url
    end

    def after_sending_reset_password_instructions_path_for(resource_name)
      droom.show_confirmation_url
    end

    def remember_original_destination
      store_full_location_for(:user, params[:backto])
    end


    # Bypass the usual store_location_for because we need to keep the full URI. 
    #
    def store_full_location_for(resource_or_scope, location)
      session_key = stored_location_key_for(resource_or_scope)
      if location
        session[session_key] = location
      end
    end
    
  end
end