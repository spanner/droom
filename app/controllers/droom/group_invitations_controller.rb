module Droom
  class GroupInvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    before_filter :get_event
    before_filter :build_group_invitation, :only => [:new]
    before_filter :find_or_build_group_invitation, :only => [:create]
    before_filter :get_group_invitation, :only => :destroy

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

    protected
    
    def get_event
      @event = Droom::Event.find(params[:event_id])
    end

    def build_group_invitation
      @group_invitation = @event.group_invitations.build(params[:group_invitation])
    end
    
    def find_or_build_group_invitation
      @group = Droom::Group.find(params[:group_invitation][:group_id])
      unless @group_invitation = @event.group_invitations.for_group(@group).first()
        @group_invitation = @event.group_invitations.build(params[:group_invitation])
      end
    end

    def get_group_invitation
      @group_invitation = @event.group_invitations.find(params[:id])
    end
    
  end
end
