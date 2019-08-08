module Droom::Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    layout :default_layout

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

    def after_sign_up_path_for(resource)
      root_url
    end

    def after_inactive_sign_up_path_for(resource)
      confirm_registration_url
    end

    def confirm
      render locals: {resource: @resource}
    end

    def default_layout
      Droom.layout
    end

  end
end