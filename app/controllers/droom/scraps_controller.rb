module Droom
  class ScrapsController < Droom::EngineController
    respond_to :html, :js, :json, :atom
    layout :no_layout_if_pjax
  
    before_filter :get_scraps, :only => [:index]
    before_filter :build_scrap, :only => [:create]
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

    def get_scraps
      @scraps = paginated(Droom::Scrap.all)
    end

    def build_scrap
      @scrap = Droom::Scrap.new(scrap_params)
      @scrap.created_by = current_user
    end

    def scrap_params
      params.require(:scrap).permit(:name, :body, :image, :description, :scraptype, :note, :event_attributes, :document_attributes)
    end

  end
end