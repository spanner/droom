module Droom
  class ScrapsController < Droom::EngineController
    respond_to :html, :js, :json, :atom
    layout :no_layout_if_pjax
  
    load_and_authorize_resource

    def index
      @scraps = paginated(@scraps, 8)
      respond_with(@scraps) do |format|
        format.js { render :partial => 'droom/scraps/stream' }
      end
    end
  
    def show
      respond_with(@scrap)
    end

    def new
      respond_with(@scrap)
    end

    def edit
      respond_with(@scrap)
    end

    def update
      @scrap.update_attributes(params[:scrap])
      respond_with(@scrap)
    end

    def create
      @scrap.update_attributes(params[:scrap])
      respond_with(@scrap)
    end
  
    def destroy
      @scrap.destroy
      head :ok
    end
    
    def feed
      
    end
    
  protected

    def scrap_parameters
      params.require(:scrap).permit(:name, :body, :image, :description, :scraptype, :note, :event_attributes, :document_attributes)
    end

  end
end