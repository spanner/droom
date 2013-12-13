module Droom::Api
  class ApiController < Droom::EngineController
    respond_to :json

    protect_from_forgery with: :null_session
    skip_before_filter :require_data_room_permission
    before_filter :set_access_control_headers
    prepend_before_filter :echo_auth
    before_filter :echo_user_status
    
    rescue_from "ActiveRecord::RecordNotFound", with: :not_found
    rescue_from "Cancan::AccessDenied", with: :not_allowed
    rescue_from "Droom::Error", with: :blew_up

    def current_ability
      @current_ability ||= Droom::Ability.new(current_user)
    end

  protected

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

  end
end