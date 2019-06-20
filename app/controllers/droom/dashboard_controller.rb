module Droom
  class DashboardController < Droom::ApplicationController
    respond_to :html, :js
    skip_authorization_check

    def index
      authorize! :read, :dashboard
      render layout: Droom.dashboard_layout.to_s
    end

  end
end