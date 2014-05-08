module Droom
  class GroupInvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    load_and_authorize_resource :event, :class => Droom::Event
    load_and_authorize_resource :group_invitation, :through => :event, :class => Droom::GroupInvitation

    def destroy
      @group_invitation.destroy
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'attending_groups'
    end
    
    def new
      respond_with @group_invitation
    end
    
    def create
      if @group_invitation.update_attributes(group_invitation_params)
        render :partial => "created"
      else
        respond_with @group_invitation
      end
    end

  protected
    
    def group_invitation_params
      params.require(:group_invitation).permit(:event_id, :group_id)
    end

  end
end
