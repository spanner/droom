module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    # before_filter :require_admin!, :except => [:index, :show]
    before_filter :get_current_person
    before_filter :get_folder
    before_filter :find_documents, :only => [:index]
    before_filter :get_document, :only => [:show, :edit, :update, :destroy]
    before_filter :build_document, :only => [:new, :create]
    
    def index
      respond_with @documents do |format|
        format.js { render :partial => 'droom/documents/documents' }
      end
    end
  
    def show
      if @document.file
        # master documents are stored in private S3 buckets
        # To keep the documents secure, we: 
        # * publish them only through this controller (so no S3 links appear on the page)
        # * deliver them only to authenticated users
        # * delivery by redirecting to a URL that expires in ten minutes
        #
        # We could channel all file delivery through this controller and may do so in future but it
        # creates a nasty performance bottleneck. For now the redirect approach seems more robust 
        # and the expiring URLs sufficiently obscure.
        #
        redirect_to @document.file.expiring_url(Time.now + 600)
      else
        raise ActiveRecord::RecordNotFound
      end
    end
    
    def new
      render 
    end

    def create
      @document.update_attributes(params[:document])
      @document.save!
      render :partial => 'created'
    end
    
    def edit
      render 
    end
    
    def update
      @document.update_attributes(params[:document])
      @document.save!
      render :partial => 'listing', :object => @document.with_event
    end

    def destroy
      @document.destroy
      head :ok
    end
    
    
  protected
    def get_folder
      @folder = Droom::Folder.find(params[:folder_id]) if params[:folder_id]
    end
    
    def build_document
      @document = @folder.documents.build(params[:document])
    end

    def get_document
      @document = @folder.documents.find(params[:id])
    end

    def find_documents
      sort_orders = {
        'asc' => "ASC",
        'desc' => "DESC"
      }
      @order = sort_orders[params[:order]] || "DESC"

      sort_parameters = {
        'name' => "droom_documents.name #{@order}",
        'filename' => "droom_documents.file_file_name #{@order}",
        'filesize' => "droom_documents.file_file_size #{@order}",
        'created' => "droom_documents.created_at #{@order}",
        'event' => "event_name #{@order}",
        'category' => "case when category_name is null then 1 else 0 end #{@order}, category_name #{@order}"
      }
      params[:sort] = 'created' unless sort_parameters[params[:sort]]
      @sort = params[:sort]
      @show = params[:show] || 10
      @page = params[:page] || 1
      
      if current_user.admin?
        @documents = Droom::Document.scoped({})
      else
        @documents = Droom::Document.visible_to(@current_person)
      end

      @documents = @documents.matching(params[:q]) unless params[:q].blank?
      @documents = @documents.order(sort_parameters[@sort]).page(@page).per(@show)
    end

  end
end