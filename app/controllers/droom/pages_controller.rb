module Droom
  class PagesController < Droom::EngineController
    respond_to :html
    before_filter :require_admin!, :except => [:index, :show]
    before_filter :get_pages
    before_filter :get_page, :only => [:show, :edit, :update, :destroy]
    before_filter :build_page, :only => [:new, :create]
    layout :no_layout_if_pjax
  
    def index
      respond_with(@pages) do |format|
        format.js {
          render :partial => 'droom/pages/pages'
        }
      end
    end

    def show
      respond_with(@page)
    end

    def new
      respond_with(@page)
    end

    def create
      if @event.save
        render :partial => "created"
      else
        respond_with @event
      end
    end
    
    def edit
      
    end

    def update
      @page.update_attributes(params[:page])
      if @page.save
        render :partial => "full_page"
      else
        respond_with @page
      end
    end

  protected

    def get_pages
      @pages = Page.all
    end
  
    def get_page
      @page = Page.find_by_slug(params[:slug]) || Page.find(params[:id])
    end

    def build_page
      @page = Page.new(params[:page])
    end
  end
end