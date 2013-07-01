module Droom
  class GroupInvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    load_and_authorize_resource :event, :class => Droom::Event
    load_and_authorize_resource :group_invitation, :through => :event, :class => Droom::Invitation

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
      if @group_invitation.save
        render :partial => "created"
      else
        respond_with @group_invitation
      end
    end

  end
end
