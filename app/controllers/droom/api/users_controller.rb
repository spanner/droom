module Droom::Api
  class UsersController < Droom::Api::ApiController

    before_filter :get_users, only: [:index]
    before_filter :build_user, only: [:create]
    load_and_authorize_resource find_by: :uid
    after_filter :set_pagination_headers, only: [:index]
    
    def index
      render json: @users.includes(:awards, :notes)
    end

    def show
      render json: @user
    end

    def update
      @user.update_attributes(user_params)
      render json: @user
    end

    def create
      @user.update_attributes(user_params)
      render json: @user
    end

    def destroy
      @user.destroy
      head :ok
    end

  protected

    def find_person
      @user = Droom::User.where(uid: params[:id]).first
      raise ActiveRecord::RecordNotFound unless @user
    end
    
    def build_user
      @user = Droom::User.new
    end

    def get_users
      users = Droom::User.in_name_order
      
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| users = users.matching(frag) }
      end

      @show = params[:show] || 20
      @page = params[:page] || 1
      if @show == 'all'
        @users = users
      else
        @users = users.page(@page).per(@show) unless 
      end
    end

    def user_params
      params.require(:user).permit(:title, :family_name, :given_name, :chinese_name, :honours, :email, :phone, :description, :address, :post_code, :country_code, :mobile, :organisation_id, :female)
    end

  end
end