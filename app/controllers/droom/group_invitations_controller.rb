module Droom
  class GroupInvitationsController < Droom::EngineController
    respond_to :js, :html
    
    before_filter :build_group_invitation, :only => [:new, :create]
    before_filter :get_group_invitation, :only => :destroy

    def destroy
      @group_invitation.destroy!
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'attending_groups'
    end
    
    def new
      render :partial => "form"
    end
    
    def create
      if @group_invitation.save
        render :partial => "created"
      else
        respond_with @group_invitation
      end
    end

    protected
    
    def build_group_invitation
      @event = Droom::Event.find(params[:event_id])
      @group_invitation = @event.group_invitations.new(params[:group_invitation])
    end

    def get_group_invitation
      @group_invitation = Droom::GroupInvitation.find(params[:id])
    end

  end
end
