module Droom
  class OrganisationsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    helper Droom::DroomHelper
  
    before_filter :authenticate_user!
    before_filter :get_users, :only => [:index]
    before_filter :find_organisations, :only => [:index]
    before_filter :get_organisation, :only => [:show, :edit, :update, :destroy]
    before_filter :build_organisation, :only => [:new, :create]

    def create
      @organisation.update_attributes(params[:organisation])
      respond_with @organisation
    end

    def update
      @organisation.update_attributes(params[:organisation])
      respond_with @organisation
    end

    def show
      respond_with @organisation
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def find_organisations
      @organisations = Droom::Organisation.order("name asc")
    end

    def get_users
      @show = params[:show] || 10
      @page = params[:page] || 1
      @users = Droom::User.order("name asc").page(@page).per(@show)
    end
    
    def get_organisation
      @organisation = Droom::Organisation.find(params[:id])
    end

    def build_organisation
      @organisation = Droom::Organisation.new(params[:organisation])
    end
  
  end
end