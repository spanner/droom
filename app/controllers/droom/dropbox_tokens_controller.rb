# This is a RESTful dropbox authentication controller. The access_token is treated as a resource.
# Later it might be generalised to handle other oauth tokens.

require 'dropbox_sdk'

module Droom
  class DropboxTokensController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
    before_filter :authenticate_user!

    before_filter :get_dropbox_session, :only => [:new, :create]
    before_filter :get_token, :only => [:show, :destroy]
    skip_before_filter :verify_authenticity_token, :only => :create
    
    def new
      session[:dropbox_session] = @dbsession.serialize
      @authorization_url = @dbsession.get_authorize_url(droom.register_dropbox_tokens_url)
      respond_with @authorization_url
    end
    
    def create
      if params[:oauth_token]
        response = @dbsession.get_access_token
        Rails.logger.warn ">>> get_access_token: #{response.inspect}"
        @dropbox_token = current_user.dropbox_tokens.create(:access_token => response.key, :access_token_secret => response.secret)
        session[:dropbox_session] = @dbsession.serialize
        flash[:panel] = 'dropbox'
        redirect_to main_app.dashboard_url
      else
        redirect_to new_dropbox_token_url
      end
    end
    
    def show
      respond_with @dropbox_token
    end
    
    def destroy
      @dropbox_token.destroy
      flash[:panel] = 'dropbox'
      flash[:notice] = t(:dropbox_access_revoked)
      redirect_to main_app.dashboard_url
    end
  
  protected
      
    def get_token
      @dropbox_token = DropboxToken.find(params[:id])
    end
    
  end
end
