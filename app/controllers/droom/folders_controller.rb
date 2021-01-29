module Droom
  class FoldersController < Droom::DroomController
    respond_to :html, :json, :js
  
    before_action :get_root_folders, :only => [:index]
    before_action :get_parent_folder, :only => [:new, :create]
    load_and_authorize_resource
    
    def index
      @folders = @folders.populated unless current_user.admin?
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
      end
    end
    
    def new
      respond_with @folder
    end

    def create
      @folder.update(folder_params)
      respond_with @folder do |format|
        format.js { render :partial => "droom/folders/folder" }
      end
    end
    
    def edit
      respond_with @folder
    end
    
    def update
      @folder.update(folder_params)
      respond_with @folder do |format|
        format.js { render :partial => "droom/folders/folder" }
      end
    end
    
    def destroy
      @folder.destroy
      head :ok
    end

    def with_parent
      
    end
    
  protected
  
    def folder_params
      params.require(:folder).permit(:name, :slug, :parent_id)
    end
    
    def get_root_folders
      @folders = Droom::Folder.roots
    end
    
    def get_parent_folder
      if @parent = Droom::Folder.find_by(id: params[:folder_id])
        @folder = @parent.children.build
      else
        @folder = Droom::Folder.new
      end
    end
 
    def get_folder_tree
      @child_map = Droom::Folder.non_roots.each_with_object({}) do |f, children|
        children[f.parent_id] ||= []
        children[f.parent_id].push(f)
      end
      @document_map = Droom::Document.all.each_with_object({}) do |d, contents|
        contents[d.folder_id] ||= []
        contents[d.folder_id].push(d)
      end
    end
  end
end