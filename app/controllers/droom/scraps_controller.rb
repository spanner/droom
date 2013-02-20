module Droom
  class ScrapsController < Droom::EngineController
    respond_to :html, :js, :json, :rss
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :scale_image_params, :only => [:create, :update]
    before_filter :find_scraps, :only => [:index]
    before_filter :get_scrap, :only => [:show, :edit, :update, :destroy, :chart]
    before_filter :build_scrap, :only => [:new, :create]

    def index
      respond_with(@scraps) do |format|
        format.js { render :partial => 'droom/scraps/stream' }
        format.rss {}
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

    def find_scraps
      @show = params[:show] || 10
      @page = params[:page] || 1
      @scraps = Droom::Scrap.page(@page).per(@show) unless @show == 'all'
    end

    def get_scrap
      @scrap = Scrap.find(params[:id])
    end

    def build_scrap
      @scrap = Scrap.new(params[:scrap])
      @scrap.scraptype ||= 'text'
    end

    def scale_image_params
      if multiplier = params[:multiplier]
        [:image_scale_width, :image_scale_height, :image_offset_left, :image_offset_top].each do |p|
          params[:scrap][p] = (params[:scrap][p].to_i * multiplier.to_i) unless params[:scrap][p].blank?
        end
      end
    end
  
  end
end