module Droom::Api
  class ApiAssetsController < Droom::Api::ApiController
    before_action :set_access_control_headers
    skip_before_action :assert_local_request
    before_action :authenticate_user!
  end
end