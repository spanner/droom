module Droom::Api
  class ApiAssetsController < Droom::Api::ApiController
    before_action :set_access_control_headers
    before_action :authenticate_user!
  end
end