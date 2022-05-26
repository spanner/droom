module Droom
  class DashboardController < Droom::DroomController
    respond_to :html, :js
    skip_authorization_check

    def index
      if current_user  
        cookies[:timezone] = ActiveSupport::TimeZone::MAPPING.map{|key, value| break value if key == current_user.timezone }
      end
      authorize! :read, :dashboard
      render layout: Droom.dashboard_layout.to_s
    end

  end
end