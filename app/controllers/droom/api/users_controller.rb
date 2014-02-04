module Droom::Api
  class UsersController < Droom::Api::ApiController

    before_filter :authenticate_user_from_header_token
    before_filter :require_local_or_authenticated_request

    before_filter :get_users, only: [:index]
    before_filter :find_or_create_user, only: [:create]
    load_resource find_by: :uid, class: "Droom::User"
    
    def index
      render json: @users
    end

    def show
      render json: @user
    end
    
    # # This is a almost always a preliminary call at the initial auth stage, 
    # # so the client is not yet setting auth headers. We look for a token in params too.
    # #
    # def authenticate
    #   token = params[:tok]
    #   if token.blank?
    #     token, options = ActionController::HttpAuthentication::Token.token_and_options(request)
    #   end
    #   if @user = Droom::User.find_by(authentication_token: token)
    #     render json: @user
    #   else
    #     head :unauthorized
    #   end
    # end
  
    # whereas deauth can only happen to an authenticated user, so we can
    # observe the header token in the usual way and close the auth session.
    #
    def deauthenticate
      Rails.logger.warn "deauthenticating #{current_user.inspect}"
      if current_user
        # to invalidate data room session, if there is one
        current_user.clear_session_id!
        # and any SSO cookie, though that should have been deleted by the client
        current_user.reset_authentication_token!
        render json: current_user
      else
        head :unauthorized
      end
    end
  
    def update
      @user.update_attributes(user_params)
      render json: @user
    end

    def create
      if @user && @user.persisted?
        render json: @user
      else
        render json: {
          errors: @user.errors.to_a
        }
      end
    end

    def destroy
      @user.destroy
      head :ok
    end

  protected

    def find_or_create_user
      if params[:user]
        if params[:user][:uid].present?
          @user = Droom::User.where(uid: params[:user][:uid]).first
        end
        if params[:user][:email].present?
          @user ||= Droom::User.where(email: params[:user][:email]).first
        end
      end
      @user ||= Droom::User.create(user_params)
    end

    def get_users
      @users = Droom::User.in_name_order
      @users = @users.where(person_uid: params[:person_uid]) if params[:person_uid].present?
      @users = @users.matching(params[:q]) if params[:q].present?
      @users
    end

    def user_params
      #TODO: close this right down once users have been imported
      params.require(:user).permit(:uid, :person_uid, :title, :family_name, :given_name, :chinese_name, :honours, :email, :phone, :description, :address, :post_code, :country_code, :mobile, :organisation_id, :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :encrypted_password, :created_at, :updated_at, :confirmed_at, :authentication_token, :password_salt)
    end

  end
end