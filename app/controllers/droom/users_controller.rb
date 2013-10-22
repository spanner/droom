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
    
    def admin
      @users = @users.in_name_order
      @users = @users.matching(params[:q]) unless params[:q].blank?
      @users = paginated(@users, 50)
      respond_with @users
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
      if params[:group_id].present?
        @user.groups << Group.find(params[:group_id])
      end
      respond_with @user
    end

    def create
      @user.assign_attributes(user_params)
      if @user.save
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
        Rails.logger.warn "user invalid: #{@user.errors.to_a.inspect}"
        render :edit
      end
    end

    def destroy
      @user.destroy
      head :ok
    end
    
    def invite
      @user.invite!
      render :partial => "droom/users/user"
    end

  protected

    def user_params
      params.require(:user).permit(:title, :family_name, :given_name, :chinese_name, :email, :password, :password_confirmation, :phone, :description, :admin, :preferences_attributes, :confirm, :old_id, :invite_on_creation, :post_line1, :post_line2, :post_city, :post_region, :post_country, :post_code, :mobile, :dob, :organisation_id, :public, :private, :female, :image, :group_ids)
    end

    def build_user
      @user = Droom::User.new(user_params)
    end
  end
end
