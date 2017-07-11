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
      if @resource
        sign_in(resource_name, @resource)
         if @resource.confirmed?
           redirect_to droom.dashboard_url
         else
           redirect_to droom.dashboard_url
         end
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

  end
end