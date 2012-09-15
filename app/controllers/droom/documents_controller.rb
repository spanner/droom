module Droom
  class DocumentsController < Droom::EngineController
    respond_to :json, :html, :js
  
    before_filter :authenticate_user!  
    before_filter :find_documents
    before_filter :get_my_documents, :only => [:index]
    
    def index
      respond_with @my_documents
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
    
    def get_my_documents
      @my_documents = current_user.person.personal_documents if current_user.person
    end
    
    def find_documents
      if params[:q].blank?
        @searching = false
        @documents = Droom::Document.scoped({})
      else
        @searching = true
        @documents = Droom::Document.name_matching(params[:q])
      end
      @show = params[:show] || 10
      @page = params[:page] || 1
      @documents.page(@page).per(@show)
    end
    
  end
end