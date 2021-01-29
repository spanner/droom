module Droom
  class PermissionsController < Droom::DroomController
    respond_to :js, :html

    load_and_authorize_resource :service, :class => Droom::Service
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
      @permission.save
      respond_with @service, @permission
    end
    
    def edit
      respond_with @permission
    end

    def update
      @permission.update(permission_params)
      respond_with @service, @permission
    end
    
    def destroy
      @permission.destroy
      head :ok
    end
  
  protected
  
    def permission_params
      params.require(:permission).permit(:name, :description)
    end
    
  end
end


