require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    before_filter :authenticate_user!
    before_filter :note_current_user
    check_authorization
    
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
      if request.headers['X-PJAX'] || request.format == 'js'
        false
      else
        Droom.layout
      end
    end
    
    def note_current_user
      Droom::User.current = current_user
    end
    
  end
end