module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    rescue_from "ActiveRecord::RecordNotFound", :with => :rescue_not_found
    rescue_from "Droom::PermissionDenied", :with => :rescue_not_allowed
    rescue_from "Droom::DroomError", :with => :rescue_bang
  protected

    def require_admin!
      raise Droom::PermissionDenied unless current_user && current_user.admin?
    end
    
    def rescue_not_found(exception)
      @exception = exception
      render :template => 'droom/errors/not_found', :status => :not_found
    end

    def rescue_not_allowed(exception)
      @exception = exception
      render :template => 'droom/errors/not_allowed', :status => :permission_denied
    end
    
    def rescue_bang(exception)
      @exception = exception
      render :template => 'droom/errors/bang', :status => 500
    end

  protected

    def no_layout_if_pjax
      if request.headers['X-PJAX']
        false
      else
        Droom.layout
      end
    end
    
    def get_current_person
      @current_person = current_user.person if current_user
    end
    
  end
end