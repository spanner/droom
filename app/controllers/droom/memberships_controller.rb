module Droom
  class MembershipsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    before_filter :build_membership, :only => [:new, :create]
    before_filter :get_membership, :only => :destroy

    def destroy
      @membership = Membership.find(params[:id])
      @group = @membership.group
      @user = @membership.user
      @membership.destroy
      render :partial => "membership_toggle"
    end
        
    def new
      if params[:user_id]
        @group = Droom::Group.find(params[:group_id])
        @user = Droom::User.find(params[:user_id])
        @membership = @group.memberships.create!(:user_id => @user.id, :group_id => @group.id)
        render :partial => "button"
      else
        respond_with @membership
      end
    end
    
    def create
      if @membership.save
        @user = @membership.user
        render :partial => "membership_toggle"
      else
        respond_with @membership
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
