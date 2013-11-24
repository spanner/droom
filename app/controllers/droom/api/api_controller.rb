module Droom::Api
  class ApiController < ApplicationController
    protect_from_forgery with: :null_session
    respond_to :json
    skip_before_filter :require_data_room_permission
    before_filter :echo_user_status

  protected
    
    def echo_user_status
      Rails.logger.warn ">>> user_signed_in? is #{user_signed_in?.inspect}"
      Rails.logger.warn "    token_and_options: #{ActionController::HttpAuthentication::Token.token_and_options(request).inspect}"
      Rails.logger.warn "    token auth header is #{request.headers["HTTP_AUTHORIZATION"]}"
      if user_signed_in?
        Rails.logger.warn "    current_user is #{current_user.inspect}"
        Rails.logger.warn "    permissions: is #{current_user.permission_codes.inspect}"
      end
    end
    
    def name_from_controller
      params[:controller].sub("Controller", "").underscore.split('/').last
    end

    def set_pagination_headers
      if results = instance_variable_get("@#{name_from_controller}")
        headers["X-Pagination"] = {
          limit: results.limit_value,
          offset: results.offset_value,
          total_count: results.total_count
        }.to_json
      end
    end
  end
end