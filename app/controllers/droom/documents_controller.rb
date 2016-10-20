module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax

    before_filter :get_folder, except: [:index]
    before_filter :select_documents, only: [:index]
    load_and_authorize_resource :document, :class => Droom::Document, :through => :folder, :shallow => true
    
    def index
      respond_with @documents do |format|
        format.js { render :partial => 'droom/documents/documents' }
      end
    end
    
    def show
      if @document.file
        redirect_to @document.file.expiring_url(Time.now + 600)
      else
        raise ActiveRecord::RecordNotFound
      end
    end
    
    def new
      render
    end

    def create
      @document.save!
      render :partial => 'created'
    end
    
    def edit
      render 
    end
    
    def update
      @document.save!
      render :partial => 'listing', :object => @document.with_event
    end

    def destroy
      @document.destroy
      head :ok
    end

  protected

    def select_documents
      if params[:q].present?
        @q = params[:q]
        terms = params[:q]
        order = {_score: :desc}
      else
        terms = "*"
        order = {name: :asc}
      end

      criteria = {}
      criteria[:event_type] = params[:event_type] if params[:event_type].present?
      criteria[:year] = params[:year] if params[:year].present?
      criteria[:content_type] = params[:content_type] if params[:content_type].present?

      fields = ["name^10", "filename^5", "content"]
      highlight = {tag: "<strong>", fields: {content: {fragment_size: 320}}}
      aggregations = {
        year: {},
        event_type: {},
        content_type: {}
      }

      @show = (params[:show].presence || 20).to_i
      @page = (params[:page].presence || 1).to_i
      @documents = Document.search terms, fields: fields, where: criteria, order: order, per_page: @show, page: @page, highlight: highlight, aggs: aggregations
    end
  
    def document_params
      if params[:document]
        params.require(:document).permit(:name, :file, :description, :folder_id)
      else
        {}
      end
    end
    
    def get_folder
      @folder = Droom::Folder.find(params[:folder_id])
    end
    
  end
end