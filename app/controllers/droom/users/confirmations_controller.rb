module Droom::Users
  class ConfirmationsController < Devise::ConfirmationsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :check_user_is_confirmed
    skip_before_action :check_user_setup
    skip_before_action :check_user_has_organisation
    layout :default_layout

    # We used to take people through a process here but by encrypting the stored token
    # devise has made confirmation a bit of a black box. These days we just redirect
    # to the dashboard, which will be interrupted with a password-setting form and
    # possibly also an organisation-joining form.
    #
    def show
      Rails.logger.warn "😈 Confirmations#show"
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      Rails.logger.warn "😈 resource: #{resource_name}: #{@resource.inspect}"
      if @resource
        sign_in(resource_name, @resource)
          Rails.logger.warn "😈 redirecting..."
         redirect_to droom.root_url
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

    def default_layout
      Droom.layout
    end

  end
end