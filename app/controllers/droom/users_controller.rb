module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :set_view, only: [:show, :edit, :update]
    before_filter :build_user, only: [:create]
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
      @users = paginated(@users, 200)
      respond_with @users
    end

    def show
      @invitation = Droom::Invitation.find(params[:invitation_id]) if params[:invitation_id].present?
      respond_with @user
    end
  
    def new
      if params[:group_id].present?
        @user.groups << Droom::Group.find(params[:group_id])
      end
      if params[:organisation_id].present? && Droom.use_organisations?
        @user.organisation = Droom::Organisation.find(params[:organisation_id])
      end
      respond_with @user
    end

    def create
      @user.update_attributes(user_params)
      respond_with @user
    end

    def edit
      respond_with @user
    end
    
    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      @user.update_attributes(user_params)
      sign_in(@user, :bypass => true) if @user == current_user        # changing the password invalidates the session
      respond_with @user
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
      params.require(:user).permit(:title, :family_name, :given_name, :chinese_name, :honours, :email, :password, :password_confirmation, :phone, :description, :admin, :gender, :preferences_attributes, :confirm, :old_id, :send_confirmation, :defer_confirmation, :address, :post_code, :country_code, :mobile, :organisation_id, :female, :image, :group_ids, preferences_attributes: [:id, :_destroy, :uuid, :key, :value])
    end

    def build_user
      @user = Droom::User.new(user_params)
    end
    
    def set_view
      @view = params[:view] if %w{listed tabled profile preferences}.include?(params[:view])
      @view ||= 'profile'
    end
  end
end
