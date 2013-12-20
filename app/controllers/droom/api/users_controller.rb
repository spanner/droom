module Droom::Api
  class UsersController < Droom::Api::ApiController
    skip_before_filter :authenticate_user!#, only: [:authenticate]
    skip_before_action :verify_authenticity_token
    before_filter :get_users, only: [:index]
    before_filter :find_or_create_user, only: [:create]
    load_resource find_by: :uid, class: "Droom::User"
    # authorize_resource except: [:authenticate]
    # after_filter :set_pagination_headers, only: [:index]
    
    def index
      render json: @users
    end

    def show
      render json: @user
    end
    
    def authenticate
      # This usually happens before the client is in a position to set the auth header token, 
      # (because we're only at the initial auth stage) so we expect token in params.
      token = params[:token]
      if token.blank?
        token, options = ActionController::HttpAuthentication::Token.token_and_options(request)
      end
      if @user && token.present? && @user.authenticate_token(token)
        render json: @user
      else
        head :unauthorized
      end
    end
  
    def deauthenticate
      Rails.logger.warn "deauthenticating #{current_user.inspect}"
      if current_user
        current_user.clear_session_id!
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
      users = Droom::User.in_name_order
      if params[:person_uid].present?
        users = users.where(person_uid: params[:person_uid])
      end
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| users = users.matching(frag) }
      end

      @users = users

      # @show = params[:show] || 20
      # @page = params[:page] || 1
      # if @show == 'all'
      #   @users = users
      # else
      #   @users = users.page(@page).per(@show)
      # end
    end

    def user_params
      #TODO: close this right down once users have been imported
      params.require(:user).permit(:uid, :title, :family_name, :given_name, :chinese_name, :honours, :email, :phone, :description, :address, :post_code, :country_code, :mobile, :organisation_id, :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :encrypted_password, :created_at, :updated_at, :confirmed_at, :authentication_token, :password_salt)
    end

  end
end