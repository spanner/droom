module Droom
  class ScrapsController < Droom::EngineController
    respond_to :html, :js, :json, :atom
    layout :no_layout_if_pjax
  
    before_filter :get_scraps, :only => [:index]
    before_filter :get_scraptype, :only => [:new, :create, :update]
    before_filter :build_scrap, :only => [:new, :create]
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
      @scrap.update_attributes(scrap_params(@scraptype))
      respond_with(@scrap)
    end

    def create
      @scrap.update_attributes(scrap_params(@scraptype))
      respond_with(@scrap)
    end
  
    def destroy
      @scrap.destroy
      head :ok
    end

  protected

    def get_scraps
      @scraps = paginated(Droom::Scrap.all)
    end

    def build_scrap
      @scrap = current_user.scraps.build(:scraptype => @scraptype)
    end

    def get_scraptype
      if params[:scrap]
        Rails.logger.warn ">>> get_scraptype. params -> '#{params[:scrap][:scraptype]}'"
        Rails.logger.warn ">>> permitted -> #{Droom.scrap_types.to_sentence}"
        @scraptype = params[:scrap][:scraptype] if Droom.scrap_types.include?(params[:scrap][:scraptype])
      end
      @scraptype ||= 'text'
    end

    def scrap_params(scraptype=@scraptype)
      Rails.logger.warn ">>> scrap_params(#{scraptype})"
      case scraptype.to_sym
      when :image then params.require(:scrap).permit(:name, :image, :note, :url, :scraptype)
      when :video then params.require(:scrap).permit(:name, :youtube_id, :note, :url, :scraptype)
      when :link then params.require(:scrap).permit(:name, :note, :url, :scraptype)
      when :event then params.require(:scrap).permit(:name, :note, :url, :scraptype, :event_attributes => [:start])
      when :document then params.require(:scrap).permit(:name, :note, :url, :scraptype, :document_attributes => [:file])
      else params.require(:scrap).permit(:name, :body, :note, :url, :scraptype)
      end
    end

  end
end