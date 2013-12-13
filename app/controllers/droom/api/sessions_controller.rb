module Droom::Api
  class SessionsController < Devise::SessionsController
    respond_to :json
    before_filter :set_access_control_headers

    def create
      build_resource
      resource = User.find_for_database_authentication(:email => params[:email])
      return invalid_login_attempt unless resource
      if resource.valid_password?(params[:password])
        resource.ensure_authentication_token!
        render :json => { :authentication_token => resource.authentication_token, :user_id => resource.id }, :status => :created
      end
    end

    def destroy
      if resource = User.find_by(authentication_token: params[:auth_token])
        resource.reset_authentication_token!
        render :json => { :message => ["Session deleted."] },  :success => true, :status => :ok
      else
        head :not_found
      end
    end
    
    def invalid_login_attempt
      warden.custom_failure!
      render :json => { :errors => ["Invalid email or password."] },  :success => false, :status => :unauthorized
    end

  protected

    def set_access_control_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
      headers["Access-Control-Allow-Methods"] = %{GET PATCH POST}
    end

  end
end