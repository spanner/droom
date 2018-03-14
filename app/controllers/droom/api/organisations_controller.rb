module Droom::Api
  class OrganisationsController < Droom::Api::ApiController

    load_and_authorize_resource class: "Droom::Organisation"
    skip_before_action :assert_local_request, only: [:register]

    def index
      render json: @organisations
    end

    def show
      render json: @organisation
    end

    def update
      if @organisation.update_attributes(organisation_params)
        render json: @organisation
      else
        render json: {errors: @organisation.errors}, status: :unprocessable_entity
      end
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

    def register
      if Droom.organisations_registerable?
        @organisation = Droom::Organisation.create organisation_params
        @organisation.send_registration_confirmation_messages
        render json: @organisation
      else
        head :not_allowed
      end
    end

    def destroy
      @organisation.destroy
      head :ok
    end

    protected

    def organisation_params
      params.require(:organisation).permit(:name, :chinese_name, :description, :phone, :address, :owner_id, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image_data, :image_name, :logo_data, :logo_name)
    end

  end
end