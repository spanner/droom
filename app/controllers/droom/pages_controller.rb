module Droom
  class PagesController < Droom::EngineController
    respond_to :html
    load_and_authorize_resource except: [:published, :welcome]
    skip_before_action :authenticate_user!, only: [:published, :welcome]

    def welcome
      if @page = Droom::Page.published.find_by(slug: 'welcome')
        render template: "droom/pages/published"
      else
        redirect_to dashboard_url
      end
    end

    def new
      @page = Droom::Page.new(slug: params[:slug])
    end

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

    # NB authored page can override built-in page template if it takes that slug.
    #
    def published
      if @page = Droom::Page.published.find_by(slug: params[:slug])
        authenticate_user! unless @page.public?
        render

      elsif lookup_context.exists?(params[:slug], 'pages', false)
        render template: "pages/#{params[:slug]}"

      elsif can?(:create, Droom::Page)
        redirect_to droom.new_page_url(slug: params[:slug])

      else
        raise ActiveRecord::RecordNotFound, "No such page."
      end
    end

  protected

    def page_params
      params.require(:page).permit(:title, :subtitle, :slug, :main_image_id, :content, :public, :publish_now)
    end

  end
end