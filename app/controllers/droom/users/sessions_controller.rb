module Droom::Users
  class SessionsController < Devise::SessionsController
    respond_to :html, :json
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token

    def stored_location_for(resource_or_scope)
      if params[:backto]
        CGI.unescape(params[:backto])
      else
        super
      end
    end

  end
end