module Droom::Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    before_action :check_email_confirmation, only: [:new, :create]
    layout :default_layout

    def after_sign_up_path_for(resource)
      if resource.organisation && !resource.organisation.external?
        already_registration_url
      else
        confirm_registration_url
      end
    end

    def after_inactive_sign_up_path_for(resource)
      confirm_registration_url
    end

    def confirm
      render locals: {resource: @resource}
      expire_data_after_sign_in!
    end

    def already
      render locals: {resource: @resource}
    end

    def sign_up(resource_name, resource)
      Rails.logger.warn("🙋‍ registration signup: sending wait and see to #{resource.email}")
      # TODO: send org_confirmation.html
    end

    def default_layout
      Droom.layout
    end
    
    def new_reg_params
      params.require(:registration).permit(:email, :token)
    end

  end
end