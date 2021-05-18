module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false

    def signmein
      if signmein_params[:u] && signmein_params[:t]
        threshold = Time.now - Droom.config.login_token_ttl
        user = Droom::User.where(uid: signmein_params[:u], login_token: signmein_params[:t]).where("login_token_created_at > ?", threshold).first
        if user
          set_flash_message!(:notice, :signed_in)
          sign_in('user', user)
          user.reset_login_token!
          respond_with user, location: after_sign_in_path_for(user)
        else
          render template: "devise/sessions/signmein_failure"
        end
      end
    end

    def stored_location_for(resource_or_scope)
      if params[:backto]
        CGI.unescape(params[:backto])
      else
        super
      end
    end

    def all_signed_out?
      !user_signed_in?
    end

    def signmein_params
      params.permit(:u, :t)
    end

  end
end