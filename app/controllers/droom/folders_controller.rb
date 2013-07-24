module Droom
  class FoldersController < Droom::EngineController
    respond_to :html, :json, :js, :zip
    layout :no_layout_if_pjax
  
    load_and_authorize_resource
    
    def index
      respond_with @folders do |format|
        format.js {
          render :partial => 'droom/folders/folders'
        }
      end
    end
  
    def show
      respond_with @folder do |format|
        format.js { 
          render :partial => 'droom/folders/folder' 
        }
        format.zip { 
          send_file @folder.documents_zipped.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@folder.slug}.zip"
        }
      end
    end
    
    def new
      respond_with @folder
    end

    def create
      respond_with @folder do |format|
        format.js { render :partial => "droom/folders/folder" }
      end
    end
    
    def edit
      respond_with @folder
    end
    
    def update
      respond_with @folder do |format|
        format.js { render :partial => "droom/folders/folder" }
      end
    end
    
    def destroy
      @folder.destroy
      head :ok
    end
    
    def dropbox
      @folder.copy_to_dropbox(current_user)
      render :partial => "folder"
    end

    def dav
      @folder.copy_to_dav
      respond_with @folder
    end
    
    def with_parent
      
    end
    
  protected
  
    def folder_params
      params.require(:folder).permit(:name, :parent_id)
    end
 
  end
end