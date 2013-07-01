module Droom
  class MembershipsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    load_and_authorize_resource :group
    load_and_authorize_resource :membership, :through => :group

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

  end
end
