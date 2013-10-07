module Droom
  class InvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    load_and_authorize_resource :event, :class => Droom::Event
    before_filter :build_invitation, only: [:create]
    load_and_authorize_resource :invitation, :through => :event, :class => Droom::Invitation
    
    def destroy
      @invitation = @event.invitations.find_by_id(params[:id])
      @invitation.destroy if @invitation
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'droom/events/invitations'
    end
    
    def new
      respond_with @invitation
    end
    
    def create
      if @invitation.update_attributes(invitation_params)
        render :partial => "created"
      else
        respond_with @invitation
      end
    end
    
    def accept
      @invitation.update_attribute(:response, 2)
      render :partial => "droom/invitations/invitation"
    end

    def refuse
      @invitation.update_attribute(:response, 0)
      render :partial => "droom/invitations/invitation"
    end

    def toggle
      @invitation.update_attribute(:response, @invitation.response == 0 ? 2 : 0)
      render :partial => "droom/invitations/invitation"
    end

  protected
  
    def build_invitation
      @invitation = @event.invitations.build
    end
  
    def invitation_params
      params.require(:invitation).permit(:event_id, :user_id)
    end

  end
end
