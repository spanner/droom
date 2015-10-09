module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_action :set_view, only: [:show, :edit, :update]
    before_action :self_unless_admin, only: [:edit, :update]
    skip_before_action :request_password_if_not_set, only: [:set_password]
    load_and_authorize_resource except: [:set_password]

    def index
      @users = @users.in_name_order
      @users = @users.matching(params[:q]) if params[:q].present?
      @users = paginated(@users, 50)
      respond_with @users do |format|
        format.js { render :partial => 'droom/users/users' }
        format.vcf { render :vcf => @users.map(&:to_vcf) }
      end
    end

    def admin
      @users = @users.in_name_order
      if params[:q].blank?
        @users = @users.in_any_directory_group
      else
        @users = @users.matching(params[:q])
      end
      @users = paginated(@users, 100)
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
      # block the automatic devise confirmation message
      @user.defer_confirmation!
      # then send confirmation once the user is saved and permissions are known
      @user.send_confirmation!
      @user.update_attributes(user_params)
      respond_with @user
    end

    def edit
      respond_with @user
    end
    
    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      if @user.update_attributes(user_params)
        sign_in(@user, :bypass => true) if @user == current_user        # changing the password invalidates the session
        respond_with @user do |f|
          f.html {
            flash[:notice] = "Thank you. Your account has been updated."
            redirect_to droom.dashboard_url
          }
          f.js {
            render partial: "droom/users/show/profile"
          }
        end
      else
        Rails.logger.warn "update failed: #{@user.errors.to_a.inspect}"
        respond_with @user
      end
    end

    ## Confirmation
    #
    # This is the destination of the password-setting form that intervenes when a new user arrives who has not yet
    # set a password. Normally this would only happen when they hit the confirmation link, which checks the account 
    # then redirects to the dashboard.
    #
    def set_password
      current_user.update_attributes(password_params.merge(confirmed: true))
      sign_in current_user, :bypass => true
      if current_user.data_room_user?
        flash[:notice] = t(:password_set)
        redirect_to params[:destination].presence || droom.dashboard_url
      else
        @omit_navigation = true
        render
      end
    end

    def destroy
      @user.destroy
      head :ok
    end

  protected

    def user_params
      params.require(:user).permit(
        :title,
        :family_name,
        :given_name,
        :chinese_name,
        :honours,
        :email,
        :password,
        :password_confirmation,
        :phone,
        :description,
        :admin,
        :gender,
        :preferences_attributes,
        :confirm,
        :old_id,
        :send_confirmation,
        :defer_confirmation,
        :address,
        :post_code,
        :country_code,
        :mobile,
        :organisation_id,
        :female,
        :image,
        group_ids: [],
        emails_attributes: [:id, :_destroy, :email, :address_type_id, :default],
        phones_attributes: [:id, :_destroy, :phone, :address_type_id, :default],
        addresses_attributes: [:id, :_destroy, :address, :address_type_id, :default],
        preferences_attributes: [:id, :_destroy, :uuid, :key, :value]
      )
    end

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    def set_view
      @view = params[:view] if %w{listed tabled profile preferences my_profile}.include?(params[:view])
      @view ||= 'profile'
    end

    def self_unless_admin
      @user = current_user unless @user && @user.admin?
    end
  end
end
