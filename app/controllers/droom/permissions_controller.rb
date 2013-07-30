module Droom
  class PermissionsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax

    load_and_authorize_resource :service, :class => Droom::Service
    before_filter :build_permission, :only => [:create]
    load_and_authorize_resource :permission, :through => :service, :class => Droom::Permission

    def index
      @permissions = Droom::Permission.all
      respond_with(@permissions)
    end
    
    def show
      respond_with @permission
    end

    def new
      respond_with @permission
    end
    
    def create
      @permission.update_attributes(permission_params)
      respond_with @service, @permission
    end
    
    def edit
      respond_with @permission
    end

    def update
      @permission.update_attributes(permission_params)
      respond_with @permission
    end
    
    def destroy
      @permission.destroy
      head :ok
    end
  
  protected
  
    def permission_params
      params.require(:permission).permit(:name, :description)
    end
    
    def build_permission
      @permission = @service.permissions.build(permission_params)
    end
    
  end
end


