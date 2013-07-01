module Droom
  class UsersController < Droom::EngineController
    helper Droom::DroomHelper
    respond_to :html, :js
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def index
      respond_with @users do |format|
        format.js { render :partial => 'droom/users/users' }
        format.vcf { render :vcf => @users.map(&:to_vcf) }
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


    def remember_token_auth
      if params[:auth_token] && user_signed_in?
        current_user.remember_me = true 
        sign_in current_user
      end
    end

  end
end
