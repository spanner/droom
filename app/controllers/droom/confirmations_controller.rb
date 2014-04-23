module Droom
  class ConfirmationsController < Devise::ConfirmationsController

    # We used to intervene here in careful steps but devise has made confirmation more of a black box by encrypting the stored
    # token. These days we just redirect to a password-setting form. 
    # TODO: make sure the password-reset mechanism works for people who wander off before setting a password here.
    #
    def show
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if self.resource && self.resource.confirmed?
        sign_in(resource_name, resource)
        render
      elsif user_signed_in?
        
        # if the user has droom access, do the usual
        # if not, we merely thank.
        #
        # We also need to strip out MSG or at least teach it to do the right thing with non-droom users. argh.
        
        redirect_to after_sign_in_path_for(current_user)
      else
        render :template => "droom/confirmations/failure" 
      end
    end

  protected
  
    def permitted_params
      params.require(:user).permit(:family_name, :given_name, :chinese_name, :password, :password_confirmation)
    end

  end
end