module Droom
  class GroupPermissionsController < Droom::DroomController
    respond_to :js, :html

    load_and_authorize_resource :group, :class => Droom::Group
    load_and_authorize_resource :group_permission, :through => :group, :class => Droom::GroupPermission

    def create
      @group_permission.save
      render :partial => 'droom/group_permissions/toggle'
    end

    def upsert
      @group_permission = Droom::GroupPermission.find_or_initialize_by(group_permission_params)
      @group_permission.delete_permissions(params[:read_permission])
      @group_permission.save
      render :partial => 'droom/group_permissions/action_menu'
    end

    def delete_by_permission_id

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
