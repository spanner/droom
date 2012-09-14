module Droom
  class DocumentsController < Droom::EngineController
    respond_to :json, :html
  
    before_filter :authenticate_user!  
    before_filter :get_documents
    
    def index
      respond_with @documents
    end
  
    def show
      @document = Droom::Document.find(params[:id])
      respond_with @document
    end
  
  protected
    
    def get_documents
      @my_documents = current_user.person.personal_documents if current_user.person
      @documents = Droom::Document.all
    end
    
  end
end