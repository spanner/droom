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
      sort_orders = {
        'asc' => "ASC",
        'desc' => "DESC"
      }
      params[:order] = 'asc' unless sort_orders[params[:order]]

      sort_parameters = {
        'name' => 'droom_documents.name',
        'filename' => 'droom_documents.file_file_name',
        'created' => 'droom_documents.created_at',
        'event' => 'event_name',
        'section' => 'case when agenda_section_name is null then 1 else 0 end, agenda_section_name'
      }
      params[:sort] = 'name' unless sort_parameters[params[:sort]]


      @by = sort_parameters[params[:sort]]
      @order = sort_orders[params[:order]]
      
      Rails.logger.warn "^^   by is #{@by} and order is #{@order}"
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @documents = Droom::Document.with_latest_event
      @documents = @documents.name_matching(params[:q]) unless params[:q].blank?
      @documents = @documents.order("#{@by} #{@order}").page(@page).per(@show)
    end
    
  end
end