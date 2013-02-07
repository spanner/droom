module Droom
  class ScrapsController < Droom::EngineController
    respond_to :html, :js, :json, :rss
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :find_scraps, :only => [:index]
    before_filter :get_scrap, :only => [:show, :edit, :update, :destroy, :chart]
    before_filter :build_scrap, :only => [:new, :create]

    def index
      respond_with(@scraps) do |format|
        format.js { render :partial => 'droom/scraps/stream' }
      end
    end
  
    def show
      respond_with(@scrap)
    end

    def edit
      respond_with(@scrap)
    end

    def update
      respond_with(@scrap)
    end

    def create
      respond_with(@scrap)
    end
  
    def destroy
      @scrap.destroy
      respond_with(@scrap)
    end

  protected

    def find_scraps
      @show = params[:show] || 20
      @page = params[:page] || 1
      @scraps = Droom::Scrap.page(@page).per(@show) unless @show == 'all'
    end

    def get_scrap
      @scrap = Scrap.find(params[:id])
    end

    def build_scrap
      @scrap = Scrap.new
    end
  
  end
end