module Droom
  class SessionsController < Devise::SessionsController
    respond_to :html, :json
    before_filter :set_access_control_headers
    skip_before_action :verify_authenticity_token
  end
end