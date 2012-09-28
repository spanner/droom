module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :require_admin!, :except => [:index, :show]
    before_filter :find_documents, :only => [:index]
    before_filter :get_document, :only => [:show, :edit, :update]
    before_filter :build_document, :only => [:new, :create]
    
    def index
      respond_with @documents do |format|
        format.js { render :partial => 'documents_table' }
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
    
    def build_document
      @document = Droom::Document.new(params[:document])
    end

    def get_document
      @document = Droom::Document.find(params[:id])
    end

    def find_documents
      sort_orders = {
        'ASC' => "ASC",
        'DESC' => "DESC"
      }
      params[:order] = 'ASC' unless sort_orders[params[:order]]

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
      @show = params[:show] || 20
      @page = params[:page] || 1
      @documents = Droom::Document.with_latest_event
      @documents = @documents.name_matching(params[:q]) unless params[:q].blank?
      @documents = @documents.order("#{@by} #{@order}").page(@page).per(@show)
    end
    
  end
end