require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper

    rescue_from "CanCan::AccessDenied", :with => :not_allowed
    
    def current_ability
      @current_ability ||= Droom::Ability.new(current_user)
    end
    
  protected
        
    def paginated(collection, default_show=10, default_page=1)
      @show = (params[:show] || default_show).to_i
      @page = (params[:page] || default_page).to_i
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

  end
end