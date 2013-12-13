require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    
    before_filter :authenticate_user_from_token!, unless: :devise_controller?
    before_filter :authenticate_user!, unless: :devise_controller?
    
    rescue_from CanCan::AccessDenied, :with => :not_allowed
    
    def current_ability
      @current_ability ||= Droom::Ability.new(current_user)
    end
    
  protected
        
    def paginated(collection, default_show=10, default_page=1)
      @show = params[:show] || default_show
      @page = params[:page] || default_page
      collection.page(@page).per(@show)
    end
    
    def not_allowed(exception)
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false }
        format.js { head :forbidden }
        format.json { head :forbidden }
      end
    end

    def no_layout_if_pjax
      Rails.logger.warn "pjax header: #{request.headers['X-PJAX'].inspect}"
      if request.headers['X-PJAX']
        false
      else
        Droom.layout
      end
    end
    
    def set_access_control_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
      headers["Access-Control-Allow-Methods"] = %{GET PATCH POST}
    end

    def set_pagination_headers
      if results = instance_variable_get("@#{name_from_controller}")
        if results.respond_to? :total_count
          headers["X-Pagination"] = {
            limit: results.limit_value,
            offset: results.offset_value,
            total_count: results.total_count
          }.to_json
        end
      end
    end

    # Token auth is expected only over json from a remote service.
    # Have to supply uid parameter too to obviate miniscule risk of timing attack.
    #
    def authenticate_user_from_token!
      uid = params[:uid].presence
      user = uid && User.find_by(uid: uid)
      if user && Devise.secure_compare(user.authentication_token, params[:user_token])
        sign_in user, store: false
      end
    end

    # Login anywhere sets a cookie that should work everywhere by providing the same
    # uid/token pair. No need for an additional save.

    # def authenticate_user_from_cookie!
    #   user_email = params[:user_email].presence
    #   user = user_email && User.find_by(email: user_email)
    #   if user && Devise.secure_compare(user.authentication_token, params[:user_token])
    #     sign_in user, store: false
    #   end
    # end

  end
end