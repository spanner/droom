module Droom
  class ConfirmationsController < Devise::ConfirmationsController

    # If user not yet confirmed, show password form (rather than just confirming, as it normal)
    # If already confirmed, allow devise to do whatever devise does.
    #
    def show
      self.resource = resource_class.find_by_confirmation_token(params[:confirmation_token])
      super if resource.confirmed?
    end

    # the purpose of this is to add another step between user creation and user confirmation, such that
    # we perform the confirmation only if a password is supplied and validates.
    #
    # NB. in the tortured RESTfulness of devise, that means turning confirmation#show into a password form
    # and using confirmations#update to update the user object accordingly.
    #
    def update
      self.resource = resource_class.find_by_confirmation_token(params[resource_name][:confirmation_token])
      
      result = resource.update_attributes(params[resource_name].except(:confirmation_token))
      
      Rails.logger.warn ">>> update_attributes gave us #{result.inspect} and password #{resource.password} / #{resource.password_confirmation}"
      Rails.logger.warn ">>> errors: #{resource.errors.full_messages}"
      
      if result && resource.password_match?
        self.resource = resource_class.confirm_by_token(params[resource_name][:confirmation_token])
        set_flash_message :notice, :confirmed
        sign_in_and_redirect(resource_name, resource)
      else
        # back to the password form
        set_flash_message :error, :password_error
        render :action => "show"
      end
    end
    
  end
end