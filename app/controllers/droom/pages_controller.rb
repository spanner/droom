module Droom
  class PagesController < Droom::EngineController
    respond_to :html
    layout :no_layout_if_pjax

    load_and_authorize_resource
  
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

  end
end