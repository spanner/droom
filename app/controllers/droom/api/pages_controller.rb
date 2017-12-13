require 'active_model_serializers'

module Droom::Api
  class PagesController < Droom::Api::ApiAssetsController

    def index
      @pages = Page.published
      render json: @pages
    end

    def show
      if @page = Page.published.find_by(slug: params[:slug])
        render
      elsif lookup_context.exists?(params[:slug], 'pages', false)
        render template: "pages/#{params[:slug]}", layout: "page"
      else
        raise ActiveRecord::RecordNotFound, "No such page."
      end
    end

  end
end