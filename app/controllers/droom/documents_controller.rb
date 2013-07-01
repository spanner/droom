module Droom
  class DocumentsController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    load_and_authorize_resource :folder, :class => Droom::Folder
    load_and_authorize_resource :document, :through => :folder, :class => Droom::Document
    
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

  end
end