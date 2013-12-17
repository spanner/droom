module Droom
  class SessionsController < Devise::SessionsController
    respond_to :html, :json
    before_filter :set_access_control_headers
  end
end