module Droom
  class PagesController < Droom::EngineController
    respond_to :html
    load_and_authorize_resource except: [:published]

    def create
      if @page.update_attributes(page_params)
        redirect_to droom.page_url(@page)
      else
        render action: :new
      end
    end

    def update
      if @page.update_attributes(page_params)
        redirect_to droom.page_url(@page)
      else
        render action: :edit
      end
    end

    def publish
      @page.publish!
      redirect_to droom.published_page_url(@page.slug)
    end

    def destroy
      @page.destroy
      redirect_to droom.pages_url
    end

    def published
      @page = Page.published.find_by(slug: params[:slug])
      render
    end

    #todo: check for renderable page if no authored page is found.
    def builtin
      if page_key = params[:page]
        render template: "pages/#{page_key}", layout: "page"
      end
    end

  protected

    def page_params
      params.require(:page).permit(:title, :slug, :main_image_id, :content, :publish_now)
    end

  end
end