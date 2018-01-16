module Droom
  class OrganisationsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    helper Droom::DroomHelper
    before_action :search_organisations, only: [:index]
    load_and_authorize_resource

    def create
      @organisation.update_attributes(organisation_params)
      respond_with @organisation
    end

    def update
      @organisation.update_attributes(organisation_params)
      respond_with @organisation
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image_date, :image_name, :logo_data, :logo_name)
      else
        {}
      end
    end

    def search_organisations
      if params[:q].present?
        query = params[:q].presence
        arguments = { order: {_score: :desc}}
      else
        query = '*'
        arguments = { order: {name: :asc}}
      end

      if params[:show] == "all"
        arguments[:limit] = 1000
      else
        arguments[:per_page] = (params[:show].presence || 50).to_i
        arguments[:page] = (params[:page].presence || 1).to_i
      end

      @organisations = Droom::Organisation.search query, arguments
    end

  end
end