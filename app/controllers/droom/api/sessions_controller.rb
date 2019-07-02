module Droom::Api
  class SessionsController < Devise::SessionsController
    respond_to :json
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    before_action :set_access_control_headers
    before_action :assert_local_request, if: :api_local?

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

    protected

    def api_controller?
      true
    end

    def api_local?
      Droom::api_local?
    end

    def assert_local_request
      if (Rails.env.production? || Rails.env.staging?) && (request.host != 'localhost' || request.port != Settings.api_port)
        raise CanCan::AccessDenied
      end
    end
  end
end