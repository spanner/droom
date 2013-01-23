module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :require_admin!, :except => [:index, :show]
    before_filter :get_current_person
    before_filter :get_folder
    before_filter :find_documents, :only => [:index]
    before_filter :get_document, :only => [:show, :edit, :update, :destroy]
    before_filter :build_document, :only => [:new, :create]
    
    def index
      respond_with @documents do |format|
        format.js { 
          if @event
            render :partial => 'documents_list'
          else
            render :partial => 'documents_table'
          end
        }
      end
    end
  
    def show
      if @document.file
        # if current_user.person && (personal_document = current_user.person.personal_version_of(@document))
        #   # personal documents are stored outside the web root so this is an internal-only redirect in nginx.
        #   redirect_to personal_document.url
        # else
        #   # master documents are stored in private S3 buckets accessible only through signed urls with a lifespan of only two minutes.
        redirect_to @document.file.expiring_url(Time.now + 120)
        # end
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
      @folder = Droom::Folder.find(params[:folder_id])
    end
    
    def build_document
      @document = @folder.documents.build(params[:document])
    end

    def get_document
      @document = @folder.documents.find(params[:id])
    end

    def find_documents
      @event = Droom::Event.find(params[:event_id]) if params[:event_id]
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
      @show = params[:show] || 50
      @page = params[:page] || 1
      
      if current_user.admin?
        @documents = Droom::Document.with_latest_event
      else
        @documents = Droom::Document.visible_to(@current_person).with_latest_event
      end

      @documents = @documents.name_matching(params[:q]) unless params[:q].blank?
      @documents = @documents.order(sort_parameters[@sort]).page(@page).per(@show)
    end

  end
end