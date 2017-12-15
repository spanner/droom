require 'active_model_serializers'

module Droom::Api
  class PagesController < Droom::Api::ApiAssetsController

    def index
      @pages = Droom::Page.published
      render json: @pages, each_serializer: Droom::PageSerializer
    end

    def show
      if @page = Droom::Page.published.find_by(slug: params[:id])
        return_page
      else
        raise ActiveRecord::RecordNotFound, "No such page."
      end
    end

    def return_page
      render json: @page, serializer: Droom::PageSerializer
    end

    def return_errors
      render json: {
        errors: @page.errors.to_a
      }
    end

  end
end