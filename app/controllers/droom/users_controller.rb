module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :authenticate_user!
    before_filter :require_admin!, :only => [:index, :new, :create, :destroy]
    before_filter :require_self_or_admin!, :only => [:edit, :update]
    before_filter :remember_token_auth
    before_filter :get_user, :only => :edit
    before_filter :get_user, :only => [:show, :edit, :update, :destroy, :welcome]

    def index
      @everyone = Droom::Person.all + Droom::User.unpersoned
    end
  
    def edit
      respond_with @user
    end
    
    # This has to handle small preference updates over js and large account-management forms over html.
    #
    def update
      if @user.update_attributes(params[:user])
        sign_in(@user, :bypass => true) if @user == current_user        # changing the password invalidates the session unless we refresh it with the new one
        respond_to do |format|
          format.js { 
            partial = params[:response_partial] || "confirmation"
            render :partial => "droom/users/#{partial}"
          }
          format.html {
            if current_user.admin? && @user != current_user
              flash[:notice] = t(:user_updated, :name => @user.name)
            else
              flash[:notice] = t(:your_preferences_saved)
            end
            redirect_to droom.dashboard_url
          }
        end
      else
        render :edit
      end
    end
  
  protected

    def get_user
      if current_user.admin? && params[:id]
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end
  
  private

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
