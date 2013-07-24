module Droom
  class OrganisationsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    helper Droom::DroomHelper
  
    load_and_authorize_resource

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
  
    def organisation_parameters
      params.require(:organisation).permit(:name, :description, :created_by, :owner, :url)
    end

  end
end