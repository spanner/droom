module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_action :set_view, only: [:show, :edit, :update]
    # before_action :self_unless_admin, only: [:edit, :update]
    skip_before_action :request_password_if_not_set, only: [:set_password]
    load_and_authorize_resource except: [:set_password]

    def index
      @users = @users.in_name_order.includes(:permissions)
      @users = @users.matching(params[:q]) unless params[:q].blank?
      @users = @users.from_email(params[:email]) unless params[:email].blank?
      @users = paginated(@users, 10)
      respond_with @users do |format|
        format.js { render :partial => 'droom/users/users' }
        format.vcf { render :vcf => @users.map(&:to_vcf) }
      end
    end

    def admin
      if params[:q].blank? && params[:award_type_code].blank? && params[:account_group].blank? && params[:account_confirmed].blank?
        group_slugs = Droom::Group.all.collect{ |r| r.slug }
        @users = Droom::User.search '*', where: {groups: group_slugs}, limit: 100, order: {name: :asc}, aggs: [:awards, :groups, :account_confirmation]
      else
        query = params[:q].presence || '*'
        filters = {}
        filters[:awards] = params[:award_type_code] if params[:award_type_code].present?
        filters[:groups] = params[:account_group] if params[:account_group].present?
        filters[:account_confirmation] = params[:account_confirmed] if params[:account_confirmed].present?
        @users = Droom::User.search query, where: filters, limit: 100, aggs: [:awards, :groups, :account_confirmation]
      end
      respond_with @users
    end

    def show
      #find_user_by_user_id
      @invitation = Droom::Invitation.find(params[:invitation_id]) if params[:invitation_id].present?
      respond_with @user do |format|
        format.js {
          render partial: "droom/users/show/#{@view}"
        }
      end
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
      @user = Droom::User.new(user_params)
      # add marker to block the automatic devise confirmation message
      @user.defer_confirmation!
      # add marker to send confirmation once the user is saved and permissions are known
      @user.send_confirmation!

      if @user.save
        respond_with @user
      end
    end

    def edit
      respond_to do |format|
        format.html {render :edit, locals: {mode: true}}
      end
    end

    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      if @user.update_attributes(user_params)
        respond_with @user, location: user_url(view: @view)
      end
    end

    def activity
      find_user_by_user_id
    end

    ## Confirmation
    #
    # This is the destination of the password-setting form that intervenes when a new user arrives who has not yet
    # set a password. Normally this would only happen when they hit the confirmation link, which checks the account
    # then redirects to the dashboard.
    #
    def set_password
      current_user.assign_attributes(password_params.merge(confirmed: true))
      if current_user.save
        sign_in current_user, :bypass => true
        if current_user.data_room_user?
          flash[:notice] = t(:password_set)
          redirect_to params[:destination].presence || droom.dashboard_url
        else
          @omit_navigation = true
          render
        end
      else
        render template: "/droom/users/request_password"
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
        :affiliation,
        :email,
        :password,
        :password_confirmation,
        :phone,
        :description,
        :admin,
        :gender,
        :dob,
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
      @view = params[:view] if %w{listed tabled profile preferences my_profile title contact personal account_info statuses groups biography }.include?(params[:view])
      #@view ||= 'profile'
    end

    def self_unless_admin
      @user = current_user unless @user && current_user.admin?
    end

    def find_user_by_user_id
      @user ||= Droom::User.find_by_id(params[:user_id])
    end
  end
end
