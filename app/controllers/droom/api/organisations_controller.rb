module Droom::Api
  class OrganisationsController < Droom::Api::ApiController

    load_and_authorize_resource class: "Droom::Organisation"

    def index
      render json: @organisations
    end

    def show
      render json: @organisation
    end

    def update
      @organisation.update_attributes(organisation_params)
      render json: @organisation
    end

    def create
      if @organisation && @organisation.persisted?
        render json: @organisation
      else
        render json: {
          errors: @organisation.errors.to_a
        }
      end
    end

    def destroy
      @organisation.destroy
      head :ok
    end

    protected

    def organisation_params
      params.require(:organisation).permit(:name, :chinese_name, :description, :phone, :address, :owner_id, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :logo_data, :logo_name
)
    end

  end
end