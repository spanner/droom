module Droom::Users
  class ConfirmationsController < Devise::ConfirmationsController

    # We used to intervene here in several steps but by encrypting the stored token 
    # devise has made confirmation a bit of a black box. These days we just redirect
    # to the dashboard, which will be interrupted with a password-setting form if no 
    # password has been set.
    #
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      @omit_navigation = true
      if @resource && @resource.confirmed?
        sign_in(resource_name, @resource)
        render
      elsif user_signed_in?
        redirect_to droom.dashboard_url
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

  end
end