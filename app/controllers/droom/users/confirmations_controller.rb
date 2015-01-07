module Droom::Users
  class ConfirmationsController < Devise::ConfirmationsController

    # We used to intervene here in several steps but by encrypting the stored token 
    # devise has made confirmation a bit of a black box. These days we just render a
    # password-setting form if no password has been set. The form puts to users#update 
    # in the usual way.
    #
    # The usual behaviour is to redirect on confirmation. We intervene here only to
    # render instead.
    #
    def show
      @resource = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if @resource && @resource.confirmed?
        # the confirmation call worked, ie the token was correct
        sign_in(resource_name, @resource)
        render
      else
        render :template => "droom/users/confirmations/failure"
      end
    end

  end
end