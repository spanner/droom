module Droom::Users
  class ConfirmationsController < Devise::ConfirmationsController

    # We used to take people through a process here but by encrypting the stored token
    # devise has made confirmation a bit of a black box. These days we just redirect
    # to the dashboard, which will be interrupted with a password-setting form and
    # possibly also an organisation-joining form.
    #
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if @resource
        sign_in(resource_name, @resource)
         redirect_to droom.dashboard_url
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

  end
end