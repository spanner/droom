module Droom
  class UsersController < ApplicationController
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :authenticate_user!, :except => [:welcome]
    before_filter :remember_token_auth
    before_filter :get_user, :only => :edit
    before_filter :get_user, :only => [:show, :edit, :update, :destroy, :welcome]
  
    def edit
      respond_with @user
    end
  
    def welcome
      if @user
        respond_with(@user)
      else
        render :template => "users/unwelcome"
      end
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
      if current_user.admin?
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end
  
  private

    def remember_token_auth
      if params[:auth_token] && user_signed_in?
        current_user.remember_me = true 
        sign_in current_user
      end
    end

  end
end
