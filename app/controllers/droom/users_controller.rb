module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax

    before_filter :build_user, :only => [:create]
    load_and_authorize_resource

    def index
      @users = @users.in_name_order
      @users = @users.matching(params[:q]) unless params[:q].blank?
      @users = paginated(@users, 50)
      respond_with @users do |format|
        format.js { render :partial => 'droom/users/users' }
        format.vcf { render :vcf => @users.map(&:to_vcf) }
      end
    end
    
    def show
      respond_with @user do |format|
        format.js { 
          @invitation = Droom::Invitation.find(params[:invitation_id]) if params[:invitation_id].present?
          render :partial => "droom/users/user" 
        }
      end
    end
  
    def new
      respond_with @user
    end

    def create
      if @user.update_attributes(user_params)
        render :partial => "droom/users/user"
      else
        render :edit
      end
    end

    def edit
      respond_with @user
    end
    
    def preferences
      respond_with @user
    end
    
    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      if @user.update_attributes(user_params)
        sign_in(@user, :bypass => true) if @user == current_user        # changing the password invalidates the session
        render :partial => "droom/users/user"
      else
        render :edit
      end
    end

    def destroy
      @user.destroy
      respond_with @user
    end
    
    def invite
      @user.invite!
      render :partial => "droom/users/user"
    end

  protected

    def user_params
      params.require(:user).permit(:title, :name, :forename, :email, :password, :password_confirmation, :phone, :description, :admin, :preferences_attributes, :confirm, :old_id, :invite_on_creation, :post_line1, :post_line2, :post_city, :post_region, :post_country, :post_code, :mobile, :dob, :organisation_id, :public, :private, :female, :image)
    end

    def build_user
      @user = Droom::User.new(user_params)
    end
  end
end
