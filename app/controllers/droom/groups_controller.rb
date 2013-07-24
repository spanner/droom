module Droom
  class GroupsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def index
      respond_with @groups do |format|
        format.js {
          render :partial => 'droom/groups/groups'
        }
      end
    end

    def new
      respond_with @group
    end

    def show
      respond_with @group do |format|
        format.js {
          render :partial => 'droom/groups/group'
        }
      end
    end

    def edit
      respond_with @group
    end

    def update
      @group.update_attributes(params[:group])
      render :partial => 'group'
    end

    def create
      if @group.update_attributes(params[:group])
        render :partial => "created"
      else
        respond_with @group
      end
    end
    
    def destroy
      @group.destroy
      head :ok
    end

  protected
  
    def group_parameters
      params.require(:group).permit(:name, :leader_id, :description)
    end

  end
end
