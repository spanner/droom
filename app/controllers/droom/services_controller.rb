module Droom
  class ServicesController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def index
      @groups = Droom::Group.all
      @group_permissions = Droom::GroupPermission.by_group_id
      respond_with(@services) do |format|
        format.js { render :partial => 'droom/services/services' }
      end
    end
    
    def show
      respond_with @service
    end
    
    def new
      respond_with @service
    end
    
    def create
      @service.update_attributes(params[:service])
      respond_with @service
    end

    def edit
      respond_with @service
    end
    
    def update
      @service.update_attributes(params[:service])
      respond_with @service
    end

    def destroy
      @service.destroy
      head :ok
    end
    
  end
end