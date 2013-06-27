module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :authenticate_user!
    before_filter :require_admin!, :only => [:index, :new, :create, :destroy]
    before_filter :get_user, :only => [:show, :edit, :update, :destroy, :welcome]
    before_filter :build_user, :only => [:new, :create]
    before_filter :require_self_or_admin!, :only => [:edit, :update]
    before_filter :remember_token_auth

    def index
      @users = Droom::User.all
    end
  
    def edit
      respond_with @user
    end
    
    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      if @user.update_attributes(params[:user])
        sign_in(@user, :bypass => true) if @user == current_user        # changing the password invalidates the session
        respond_to do |format|
          format.js { 
            partial = params[:response_partial] || "user"
            render :partial => "droom/users/#{partial}"
          }
          format.html {
            flash[:notice] = @user != current_user ? t(:user_updated, :name => @user.name) : flash[:notice] = t(:your_preferences_saved)
            render :partial => "droom/users/user"
          }
        end
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

    def get_user
      if current_user.admin? && params[:id]
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end
    
    def get_groups
      @groups = Droom::Group.all
    end
  
    def build_user
      @organisation = Droom::Organisation.find(params[:organisation_id]) if params[:organisation_id]
      @user = Droom::User.new(params[:user])
      @user.organisation = @organisation if @organisation
    end

    def find_users
      if current_user.admin?
        @users = Droom::User.scoped({})
      else
        @users = Droom::User.visible_to(current_user)
      end
      
      unless params[:q].blank?
        @searching = true
        @people = @people.matching(params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @people = @people.page(@page).per(@show)
    end
 
    def require_self_or_admin!
      raise Droom::PermissionDenied unless current_user && (current_user.admin? || @user == current_user)
    end

    def remember_token_auth
      if params[:auth_token] && user_signed_in?
        current_user.remember_me = true 
        sign_in current_user
      end
    end

  end
end
