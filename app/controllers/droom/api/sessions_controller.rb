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

    def api_controller?
      true
    end

  end
end