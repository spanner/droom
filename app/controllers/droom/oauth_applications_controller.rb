module Droom
  class OauthApplicationsController < Doorkeeper::ApplicationsController
    layout "doorkeeper/application"
    before_filter :authenticate_user!
    before_filter :require_admin!

  protected

    def droom_layout
      Droom.layout
    end
    
    def require_admin!
      raise Droom::PermissionDenied unless current_user && current_user.admin?
    end

  end
end
