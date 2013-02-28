module Droom
  class FoldersController < Droom::EngineController
    respond_to :html, :json, :js, :zip
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :find_folders, :only => [:index]
    before_filter :get_folder, :only => [:show, :edit, :update, :destroy, :dropbox]
    before_filter :build_folder, :only => [:new, :create]
    
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
      @folder.update_attributes(params[:folder])
      respond_with @folder do |format|
        format.js { render :partial => "droom/folders/folder" }
      end
    end
    
    def edit
      respond_with @folder
    end
    
    def update
      @folder.update_attributes(params[:folder])
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
    
  protected
    
    def build_folder
      if @parent = Droom::Folder.find_by_id(params[:folder_id])
        @folder = @parent.children.build(params[:folder])
      else
        @folder = Droom::Folder.new(params[:folder])
      end
    end

    def get_folder
      @folder = Droom::Folder.find(params[:id])
    end

    def find_folders
      if current_user.admin?
        @folders = Droom::Folder.roots
      else
        @folders = Droom::Folder.visible_to(current_person).roots.populated
      end
    end
    
  end
end