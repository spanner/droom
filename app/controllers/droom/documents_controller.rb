module Droom
  class DocumentsController < Droom::EngineController
    respond_to :json, :html, :js
  
    before_filter :authenticate_user!  
    before_filter :find_documents
    
    
    def index
      respond_to do |format|
        format.html
        format.js { render :partial => 'documents_table' }
      end
    end
    
    def search
      respond_with @documents do |format|
        format.js { render :partial => 'search_results' }
      end
    end
  
    def show
      @download = Droom::Document.find(params[:id])
      # raise ReaderError::AccessDenied, t("downloads_extension.permission_denied") unless @download.visible_to?(current_reader)
      response.headers['X-Accel-Redirect'] = @download.document.url
      response.headers["Content-Type"] = @download.document_content_type
      response.headers['Content-Disposition'] = "attachment; filename=#{@download.document_file_name}" 
      response.headers['Content-Length'] = @download.document_file_size
      render :nothing => true
    end
  
  protected
    
    def find_documents    
      if params[:q].blank?
        @searching = false
        @documents = Droom::Document.with_latest_event
      else
        @searching = true
        @documents = Droom::Document.with_latest_event.name_matching(params[:q])
      end
      @show = params[:show] || 10
      @page = params[:page] || 1
      @documents.page(@page).per(@show)

      sort_parameters = {
        'created' => 'documents.created_at',
        'event' => 'event_name'
      }

      @by = params[:sort] || 'documents.created_at'
      @order = params[:order] || 'DESC'
      @documents = @documents.order("#{@by} #{@order}")
    end
    
  end
end