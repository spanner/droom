# This is a RESTful dropbox authentication controller. The access_token is treated as a resource.
# Later it might be generalised to handle other oauth tokens.

require 'dropbox_sdk'

module Droom
  class DropboxTokensController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
    before_filter :authenticate_user!

    before_filter :get_session, :only => [:new, :create]
    before_filter :get_token, :only => [:show, :destroy]
    
    def new
      session[:dropbox_session] = @dbsession.serialize
      @authorization_url = @dbsession.get_authorize_url(droom.register_dropbox_tokens_url)
      respond_with @authorization_url
    end
    
    def create
      if params[:oauth_token]
        @dropbox_token = current_user.dropbox_tokens.create(:access_token => params[:oauth_token])
        session[:dropbox_session] = @dbsession.serialize
        session[:panel] = 'dropbox'
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
      head :ok
    end
  
  protected
  
    def get_session
      if session[:dropbox_session]
        @dbsession = DropboxSession.deserialize(session[:dropbox_session])
      else
        @dbsession = DropboxSession.new(Droom.dropbox_app_key, Droom.dropbox_app_secret)
      end
    end
    
    def get_token
      @dropbox_token = DropboxToken.get(params[:id])
    end
    
  end
end
