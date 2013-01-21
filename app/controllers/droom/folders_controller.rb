module Droom
  class FoldersController < Droom::EngineController
    respond_to :html, :js, :json
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :find_folders, :only => [:index]
    before_filter :get_folder, :only => [:show]
    
    def index
      respond_with @folders
    end
  
    def show
      respond_with @folder
    end
    
  protected
    
    def get_folder
      @folder = Droom::Folder.find(params[:id])
    end

    def find_folders
      if current_user.admin?
        @folders = Droom::Folder.roots
      else
        @folders = Droom::Folder.visible_to(@current_person).roots
      end
    end
    
  end
end