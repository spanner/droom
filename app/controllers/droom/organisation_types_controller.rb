module Droom
  class OrganisationTypesController < Droom::ApplicationController
    respond_to :html, :js
    load_and_authorize_resource

    def index
      respond_with @organisation_types do |format|
        format.js {
          render :partial => 'droom/organisation_types/organisation_types'
        }
      end
    end

    def new
      respond_with @organisation_type
    end

    def show
      respond_with @organisation_type
    end

    def edit
      respond_with @organisation_type
    end

    def update
      @organisation_type.update_attributes(organisation_type_params)
      render :partial => 'organisation_type'
    end

    def create
      if @organisation_type.update_attributes(organisation_type_params)
        render :partial => "created"
      else
        respond_with @organisation_type
      end
    end
    
    def destroy
      @organisation_type.destroy
      head :ok
    end

  protected
  
    def organisation_type_params
      params.require(:organisation_type).permit(:name, :description, :public, :private)
    end

  end
end
