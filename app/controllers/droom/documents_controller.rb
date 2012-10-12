module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :require_admin!, :except => [:index, :show]
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
      if current_user.person && @document.file
        if personal_document = current_user.person.personal_version_of(@document)
          # personal documents are stored outside the web root so this is an internal-only redirect in nginx.
          redirect_to personal_document.url
        else
          # master documents are stored in private S3 buckets accessible only through signed urls with a lifespan of only two minutes.
          redirect_to @document.file.expiring_url(Time.now + 120)
        end
      end
    end
    
    def new
      render :partial => "form"
    end

    def create
      if @event
        @event.save!
      end
      @document.save!
      render :partial => 'created'
    end
    
    def edit
      render :partial => "form"
    end
    
    def update
      @document.update_attributes(params[:document])
      @document.save!
      render :partial => 'table_document', :object => @document.with_event
    end

    def destroy
      @document.destroy
      head :ok
    end
    
    
  protected
    
    def build_document
      params[:document] ||= {}
      if params[:event_id] || params[:document][:event_id]
        @event = Droom::Event.find(params[:event_id] || params[:document][:event_id])
        @document = @event.documents.new(params[:document])
        @category = @event.categories.find(params[:category_name]) if params[:category_name]
      else
        @document = Droom::Document.new(params[:document])
      end
    end

    def get_document
      @document = Droom::Document.find(params[:id])
    end

    def find_documents
      @event = Droom::Event.find(params[:event_id]) if params[:event_id]
      sort_orders = {
        'ASC' => "ASC",
        'DESC' => "DESC"
      }
      params[:order] = 'DESC' unless sort_orders[params[:order]]

      sort_parameters = {
        'name' => 'droom_documents.name',
        'filename' => 'droom_documents.file_file_name',
        'filesize' => 'droom_documents.file_file_size',
        'created' => 'droom_documents.created_at',
        'event' => 'event_name',
        'category' => 'case when category_name is null then 1 else 0 end, category_name'
      }
      params[:sort] = 'created' unless sort_parameters[params[:sort]]

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