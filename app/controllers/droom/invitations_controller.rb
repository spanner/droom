module Droom
  class InvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    before_filter :build_invitation, :only => [:new, :create]
    before_filter :get_invitation, :only => :destroy

    def destroy
      @invitation.destroy
      head :ok
    end
    
    def index
      @event = Droom::Event.find(params[:event_id])
      render :partial => 'attending_people'
    end
    
    def new
      render :partial => "form"
    end
    
    def create
      if @invitation.save
        render :partial => "created"
      else
        respond_with @invitation
      end
    end

    protected
    
    def build_invitation
      @event = Droom::Event.find(params[:event_id])
      @invitation = @event.invitations.new(params[:invitation])
    end

    def get_invitation
      @invitation = Droom::Invitation.find(params[:id])
    end

  end
end
