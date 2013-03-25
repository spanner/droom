require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController

    before_filter :authenticate_user!
    before_filter :note_current_user
    
  protected

    def require_admin!
      raise Droom::PermissionDenied unless current_user && current_user.admin?
    end
    
    def no_layout_if_pjax
      if request.headers['X-PJAX']
        false
      else
        Droom.layout
      end
    end
    
    def note_current_user
      User.current = current_user
    end
    
  end
end