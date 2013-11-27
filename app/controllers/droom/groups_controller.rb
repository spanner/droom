module Droom
  class GroupsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax

    before_filter :get_groups, :only => [:index]
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
      @users = paginated(@group.users, 20)
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
      @group.update_attributes(group_params)
      render :partial => 'group'
    end

    def create
      if @group.update_attributes(group_params)
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
  
    def group_params
      params.require(:group).permit(:name, :leader_id, :description)
    end
    
    def get_groups
      if can? :manage, Droom::Group
        @groups = Droom::Group.order("directory DESC, name ASC")
      else
        @groups = Droom::Group.shown_in_directory.accessible_by(current_ability).order("name ASC")
      end
    end

  end
end
