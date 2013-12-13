module Droom
  class SessionsController < Devise::SessionsController
    respond_to :html, :json
    before_filter :set_access_control_headers

    def show
      # check that a given uid/auth token combination is still valid
    end

    # POST /resource/sign_in
    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => after_sign_in_path_for(resource)
    end

  end
end