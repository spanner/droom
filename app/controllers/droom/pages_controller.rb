module Droom
  class PagesController < Droom::EngineController
    respond_to :html
    load_and_authorize_resource find_by: :slug

    def create
      @page.update_attributes(page_params)
      render
    end
        
    def update
      @page.update_attributes(page_params)
      render
    end
    
    def destroy
      @page.destroy
      redirect_to droom.pages_url
    end

    def published
      @page = Page.published.find_by(slug: params[:slug])
      @render
    end

    def builtin
      if page_key = params[:page]
        render template: "pages/#{page_key}", layout: "page"
      end
    end

  protected

    def page_params
      params.require(:page).permit(:title, :slug, :image_id, :content, :publish_now)
    end

  end
end