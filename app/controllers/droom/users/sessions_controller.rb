module Droom::Users
  class SessionsController < Devise::SessionsController
    before_action :set_access_control_headers

    def new
      if @page = Droom::Page.published.find_by(slug: "_welcome")
        render template: "droom/pages/published", layout: Droom.page_layout
      else
        super
      end
    end

    def stored_location_for(resource_or_scope)
      if params[:backto]
        CGI.unescape(params[:backto])
      else
        super
      end
    end

  end
end