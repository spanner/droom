module Droom::Api
  class UsersController < Droom::Api::ApiController

    before_action :get_users, only: [:index]
    before_action :find_or_create_user, only: [:create]
    load_resource find_by: :uid, class: "Droom::User", except: [:authenticate]

    def index
      render json: @users
    end

    def show
      render json: @user
    end

    # This would usually be a session-init call from a front end SPA
    #
    def whoami
      render json: current_user
    end

    # This is called on every request by a remote service.
    # Lots of care has to be taken here, to respond quickly but lapse correctly,
    # and never to set up a cascade of mutual enquiry.
    #
    def authenticate
      token = params[:tok]
      Rails.logger.warn "⚠️ authenticate: #{params[:tok]}"
      @user = Droom::User.find_by(authentication_token: token)
      Rails.logger.warn "⚠️ -> #{@user.inspect}"
      if @user
        # ie. if user includes timeoutable...
        if @user.respond_to(:timedout?) && @user.last_request_at?
          Rails.logger.warn "⚠️ checking timeout vs #{@user.last_request_at}"
          # here we borrow the devise timeout strategy but cannot refer to the session,
          # so we use a last_request_at column.
          if @user.timedout?(@user.last_request_at)
            Rails.logger.warn "⚠️ -> timed out"
            render json: { errors: "Session timed out" }, status: :unauthorized
          else
            Rails.logger.warn "⚠️ -> we good"
            # last_request_at has to be touched on requests to any of our services,
            # so we do it in a Warden callback after any successful authentication, including this one because of this otherwise ineffective sign_in call.
            sign_in @user
            render json: @user
          end
        else
          sign_in @user
          render json: @user
        end
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
      params.require(:user).permit(:uid, :person_uid, :title, :family_name, :given_name, :chinese_name, :honours, :affiliation, :email, :phone, :mobile, :description, :address, :post_code, :correspondence_address, :country_code, :organisation_id, :female, :defer_confirmation, :send_confirmation, :password, :password_confirmation, :confirmed, :confirmed_at, :image_data, :image_name)
    end

  end
end
