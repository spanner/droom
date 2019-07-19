module Droom::Api
  class SessionsController < Devise::SessionsController
    include Droom::Concerns::LocalApi

    respond_to :json
    skip_before_action :verify_authenticity_token, raise: false
    before_action :set_access_control_headers

    # POST /api/users/sign_in
    def create
      self.resource = warden.authenticate(auth_options)
      if resource
        sign_in(resource_name, resource)
        yield resource if block_given?
        render json: resource
      else
        head :unauthorized
      end
    end

    # This is called on every request by a remote service.
    # Lots of care has to be taken here, to respond quickly but lapse correctly,
    # and never to set up a cascade of mutual enquiry.
    #
    def authenticate
      token = params[:tok]
      Rails.logger.warn "⚠️ authenticate: #{params[:tok]}"
      @user = Droom::User.find_by(authentication_token: token)
      Rails.logger.warn "⚠️ -> #{@user.inspect}"
      if @user
        # ie. if user includes timeoutable...
        if @user.respond_to?(:timedout?) && @user.last_request_at?
          Rails.logger.warn "⚠️ checking timeout vs #{@user.last_request_at}"
          # here we borrow the devise timeout strategy but cannot refer to the session,
          # so we use a last_request_at column.
          if @user.timedout?(@user.last_request_at)
            Rails.logger.warn "⚠️ -> timed out"
            render json: { errors: "Session timed out" }, status: :unauthorized
          else
            Rails.logger.warn "⚠️ -> we good"
            # last_request_at has to be touched on requests to any of our services,
            # so we do it in a Warden callback after any successful authentication, including this one because of this otherwise ineffective sign_in call.
            sign_in @user
            render json: @user
          end
        else
          sign_in @user
          render json: @user
        end
      else
        render json: { errors: "Token not recognised" }, status: :unauthorized
      end
    end

    # Deauth is used to achieve single-sign-out. It changes the auth token and session id
    # so that neither the data room session cookie nor the domain auth cookie can identify a user.
    #
    def deauthenticate
      token = params[:tok]
      if @user = Droom::User.find_by(authentication_token: token)
        @user.reset_session_id!
        @user.reset_authentication_token!
        render json: @user
      else
        head :unauthorized
      end
    end


    def api_controller?
      true
    end

  end
end