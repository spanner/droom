module Droom
  class MembershipsController < Droom::EngineController
    respond_to :js, :html
    
    before_filter :build_membership, :only => [:new, :create]
    before_filter :get_membership, :only => :destroy

    def destroy
      @membership.destroy
      head :ok
    end
        
    def new
      render :partial => "form"
    end
    
    def create
      if @membership.save
        render :partial => 'member'
      end
    end

    protected
    
    def build_membership
      @group = Droom::Group.find(params[:group_id])
      @membership = @group.memberships.new(params[:membership])
    end

    def get_membership
      @membership = Droom::Membership.find(params[:id])
    end

  end
end
