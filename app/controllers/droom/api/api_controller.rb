module Droom::Api
  class ApiController < Droom::EngineController

    respond_to :json
    before_filter :set_access_control_headers
    before_filter :assert_local_request
    skip_before_filter :authenticate_user!
    skip_before_filter :require_data_room_permission
    skip_before_action :verify_authenticity_token
    
    rescue_from "ActiveRecord::RecordNotFound", with: :not_found
    rescue_from "Droom::Error", with: :blew_up

    def current_ability
      @current_ability ||= Droom::Ability.new(current_user)
    end

  protected
    
    def assert_local_request
      raise CanCan::AccessDenied if (Rails.env.production? || Rails.env.staging?) && (request.host != 'localhost' || request.port != Settings.api_port)
    end

    def not_found(exception)
      render json: { errors: exception.message }.to_json, status: :not_found
    end

    def not_allowed(exception)
      render json: { errors: "You do not have permission to access that resource" }.to_json, status: :forbidden
    end

    def blew_up(exception)
      render json: { errors: exception.message }.to_json, status: :internal_server_error
    end
    
    def echo_auth
      Rails.logger.warn "??? token_and_options: #{ActionController::HttpAuthentication::Token.token_and_options(request).inspect}"
      Rails.logger.warn "    token auth header is #{request.headers["HTTP_AUTHORIZATION"]}"
    end

    def echo_user_status
      Rails.logger.warn ">>> user_signed_in? is #{user_signed_in?.inspect}"
      if user_signed_in?
        Rails.logger.warn "    current_user is #{current_user.inspect}"
        Rails.logger.warn "    permissions: is #{current_user.permission_codes.inspect}"
      end
    end
    
    def name_from_controller
      params[:controller].sub("Controller", "").underscore.split('/').last
    end
    
    def api_controller?
      true
    end
  end
end