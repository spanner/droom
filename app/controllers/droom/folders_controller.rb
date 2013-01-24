module Droom
  class FoldersController < Droom::EngineController
    respond_to :html, :json, :js, :zip
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :find_folders, :only => [:index]
    before_filter :get_folder, :only => [:show, :dropbox]
    
    def index
      respond_with @folders
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
    
    def dropbox
      @folder.copy_to_dropbox
      respond_with @folder
    end

    def dav
      @folder.copy_to_dav
      respond_with @folder
    end
    
  protected
    
    def get_folder
      @folder = Droom::Folder.find(params[:id])
    end

    def find_folders
      if current_user.admin?
        @folders = Droom::Folder.roots.populated
      else
        @folders = Droom::Folder.visible_to(@current_person).roots.populated
      end
    end
    
  end
end