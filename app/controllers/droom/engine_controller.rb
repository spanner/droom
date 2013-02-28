require 'dropbox_sdk'

module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper

    before_filter :authenticate_user!
    before_filter :note_current_user

    helper_method :current_person, :dropbox_session
    
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

    def current_person
      current_user.person if current_user
    end
    
    def dropbox_session
      # note that we usually don't want to pick up the existing dropbox session. That happens in the dropbox_tokens_controller, when
      # following up an access token round trip, but in the view any existing session has probably expired and we're better off with a new one.
      DropboxSession.new(Droom.dropbox_app_key, Droom.dropbox_app_secret)
    end
    
  end
end