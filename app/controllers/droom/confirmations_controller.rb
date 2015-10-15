module Droom
  class ConfirmationsController < Devise::ConfirmationsController

    # If user not yet confirmed, show password form (rather than just confirming, as is normal)
    # If already confirmed, allow devise to do whatever a devise does.
    #
    def show
      if self.resource = resource_class.confirm_by_token(params[:confirmation_token])
        if resource.confirmed?
          redirect_to after_sign_in_path_for(resource)
        else
          render
        end
      elsif user_signed_in?
        redirect_to after_sign_in_path_for(current_user)
      else
        render :template => "devise/confirmations/failure"
      end
    end

    # the purpose of this is to add another step between user creation and user confirmation, such that
    # we perform the confirmation only if a password is supplied and validates.
    #
    # NB. in the tortured RESTfulness of devise, that means turning confirmation#show into a password form
    # and using confirmations#update to update the user object accordingly.
    #
    def update
      if self.resource = resource_class.where(id: params[:id], confirmation_token: params[resource_name][:confirmation_token]).first
        result = resource.update_attributes(permitted_params)
        if result && resource.password_match?
          set_flash_message :notice, :confirmed
          resource.confirm!
          sign_in(resource_name, resource)
          respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
        else
          # back to the password form
          set_flash_message :error, :password_error
          render :action => "show"
        end
      else
        render :template => "devise/confirmations/failure"
      end
    end

    def after_confirmation_path_for(resource_name, resource)
      dashboard_url
    end

  protected
  
    def permitted_params
      params.require(:user).permit(:family_name, :given_name, :chinese_name, :password, :password_confirmation)
    end

  end
end