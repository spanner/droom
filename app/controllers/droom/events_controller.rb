module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "icalendar"
    respond_to :html, :json, :ics, :js
    layout :no_layout_if_pjax
    
    before_filter :get_events, :only => [:index]
    before_filter :build_event, :only => [:create]
    load_and_authorize_resource

    def index
      respond_with @events do |format|
        format.js { render :partial => 'droom/events/events' }
      end
    end

    def calendar
      respond_with @events do |format|
        format.js { render :partial => 'droom/events/calendar' }
      end
    end

    def show
      respond_with @event do |format|
        format.js { render :partial => 'droom/events/event' }
        format.zip { send_file @event.documents_zipped.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@event.slug}.zip" }
      end
    end

    def new
      respond_with @event
    end

    def create
      if @event.save
        render :partial => "event"
      else
        respond_with @event
      end
    end

    def update
      if @event.update_attributes(event_params)
        render :partial => "event"
      else
        respond_with @event
      end
    end

    def destroy
      @event.destroy
      head :ok
    end

  protected
  
    def get_events
      @events = Droom::Event.accessible_by(current_ability)
      if params[:direction] == 'past'
        @events = @events.past.order('start DESC')
        @direction = "past"
      else
        @events = @events.future_and_current.order('start ASC')
        @direction = "future"
      end
      @events = paginated(@events)
    end
    
    def build_event
      @event = Droom::Event.new(event_params)
      @event.created_by = current_user
    end
    
    def event_params
      params.require(:event).permit(:name, :description, :event_set_id, :all_day, :master_id, :url, :start_date, :start_time, :finish_date, :finish_time, :venue_id, :venue_name)
    end

  end
end