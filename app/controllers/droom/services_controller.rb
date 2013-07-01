module Droom
  class ServicesController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def index
      @groups = Droom::Group.all
      @group_permissions = Droom::GroupPermission.by_group_id
      respond_with(@services)
    end
    
  end
end