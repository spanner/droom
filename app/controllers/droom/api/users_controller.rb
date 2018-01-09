module Droom::Api
  class UsersController < Droom::Api::ApiController

    before_action :assert_local_request
    before_action :get_users, only: [:index]
    before_action :find_or_create_user, only: [:create]
    load_resource find_by: :uid, class: "Droom::User", except: [:authenticate]

    def index
      render json: @users
    end

    def show
      render json: @user
    end

    def whoami
      render json: current_user
    end

    # This is a almost always a preliminary call at the initial auth stage,
    # so the client is not yet setting auth headers. We look for a token in params too.
    #
    def authenticate
      token = params[:tok]
      if @user = Droom::User.find_by(authentication_token: token)
        render json: @user
      else
        render json: { errors: "Token not recognised" }, status: :unauthorized
      end
    end

    # Deauth is used to achieve single-sign-out. It changes the auth token and session id
    # so that neither the data room session cookie nor the domain auth cookie can identify a user.
    #
    def deauthenticate
      token = params[:tok]
      if @user = Droom::User.find_by(authentication_token: token)
        @user.reset_session_id!
        @user.reset_authentication_token!
        render json: @user
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
        render json: { errors: @user.errors.to_a }
      end
    end

    def destroy
      @user.destroy
      head :ok
    end

    def reindex
      @user.reindex_async
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
      params = user_params
      # remotely created users are not usually meant to access the data room, but can set send_confirmation if that's what they want.
      params[:defer_confirmation] = true
      Rails.logger.warn "---> creating user with #{params.inspect}"
      @user ||= Droom::User.create(params)
    end

    def get_users
      @users = Droom::User.in_name_order
      @users = @users.where(person_uid: params[:person_uid]) if params[:person_uid].present?
      @users = @users.matching_name(params[:name_q]) if params[:name_q].present?
      @users = @users.matching_email(params[:email_q]) if params[:email_q].present?
      @users = @users.from_email(params[:email]) unless params[:email].blank?
      @users = @users.matching(params[:q]) if params[:q].present?
      @users = @users.limit(params[:limit]) if params[:limit].present?
      @users
    end

    def user_params
      params.require(:user).permit(:uid, :person_uid, :title, :family_name, :given_name, :chinese_name, :honours, :affiliation, :email, :phone, :description, :address, :post_code, :correspondence_address, :country_code, :mobile, :organisation_id, :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :confirmed_at, :image_data, :image_name)
    end

  end
end
