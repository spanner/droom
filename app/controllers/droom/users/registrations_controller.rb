module Droom::Users
  class RegistrationsController < Devise::SessionsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token

    def new
      if Droom.registerable?
        if @page = Droom::Page.published.find_by(slug: "_signup")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          super
        end
      else
        head :forbidden
      end
    end

  end
end