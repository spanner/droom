module Droom
  class GroupsController < Droom::EngineController
    respond_to :html

    before_filter :build_group, :only => [:new, :create]
    before_filter :get_group, :only => [:show, :edit, :update, :destroy]
    before_filter :get_groups, :only => :index

    def index
      respond_with @groups do |format|
        format.js {
          render :partial => 'droom/groups/groups'
        }
      end
    end

    def new
      render :partial => "form"
    end

    def show
      respond_with @group
    end

    def edit
      respond_with @group
    end

    def update
      @group.update_attributes(params[:group])
      render :partial => 'group'
    end

    def create
      if @group.save
        render :partial => "group"
      else
        respond_with @group
      end
    end
    
    def destroy
      @group.destroy
      head :ok
    end

  protected

    def build_group
      @group = Droom::Group.new(params[:group])
    end

    def get_group
      @group = Droom::Group.find(params[:id])
    end
    
    def get_groups
      @groups = Droom::Group.all
    end
  
  end
end
