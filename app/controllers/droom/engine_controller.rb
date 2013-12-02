require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    
    before_filter :authenticate_user!
    before_filter :strengthen_parameters
    check_authorization
    
    rescue_from CanCan::AccessDenied, :with => :not_allowed
    
    def current_ability
      @current_ability ||= Droom::Ability.new(current_user)
    end
    
  protected
    
    # Until cancan is updated for rails 4, we intervene so that
    # strong-parameter permissions are applied before cancan gets there.
    # Each controller has to define a [resource]_params method.
    
    def strengthen_parameters
      resource = controller_path.singularize.gsub('/', '_').to_sym
      method = "#{resource}_params"
      params[resource] &&= send(method) if respond_to?(method, true)
    end
    
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
    
  end
end