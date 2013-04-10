module Droom
  class InvitationsController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
    
    before_filter :get_event
    before_filter :build_invitation, :only => [:new]
    before_filter :find_or_build_invitation, :only => [:create]
    before_filter :get_invitation, :only => [:accept, :refuse, :toggle]

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
      if @invitation.save
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
    
    def get_event
      @event = Droom::Event.find(params[:event_id])
    end
    
    def build_invitation
      @invitation = @event.invitations.build(params[:invitation])
    end
    
    def find_or_build_invitation
      @person = Droom::Person.find(params[:invitation][:person_id])
      unless @invitation = @event.invitations.for_person(@person).first()
        @invitation = @event.invitations.build(params[:invitation])
      end
    end

    def get_invitation
      @invitation = @event.invitations.find(params[:id])
    end

  end
end
