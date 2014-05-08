module Droom
  class GroupPermissionsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    load_and_authorize_resource :group, :class => Droom::Group
    load_and_authorize_resource :group_permission, :through => :group, :class => Droom::GroupPermission
    
    def create
      @group_permission.save
      render :partial => 'droom/group_permissions/toggle'
    end

    def destroy
      @group_permission.destroy
      render :partial => 'droom/group_permissions/toggle'
    end

  protected
  
    def group_permission_params
      params.require(:group_permission).permit(:permission_id, :group_id)
    end

  end
end
