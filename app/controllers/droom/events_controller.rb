require 'tod'

module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "icalendar"
    respond_to :html, :json, :ics, :js
    layout :no_layout_if_pjax
    
    before_filter :get_events, :only => [:index]
    before_filter :composite_dates, :only => [:update, :create]
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
      events = Droom::Event.accessible_by(current_ability)
      if Droom.separate_calendars?
        events = events.in_calendar(Droom::Calendar.where(:name => "main").first_or_create)
      end
      @past_events = paginated(events.past.order('start DESC'))
      @events = paginated(events.future_and_current.order('start ASC'))
    end
    
    def build_event
      @event = Droom::Event.new(event_params)
      @event.created_by = current_user
    end
    
    def composite_dates
      if params[:event]
        if params[:event][:start_date].present?
          date = Time.zone.parse(params[:event][:start_date])
          if params[:event][:start_time].present?
            start_time = TimeOfDay.parse(params[:event][:start_time])
            params[:event][:start] = start_time.on date
          end
          if params[:event][:finish_time].present?
            finish_time = TimeOfDay.parse(params[:event][:finish_time])
            params[:event][:finish] = finish_time.on date
          end
        end
      end
    end
    
    def event_params
      params.require(:event).permit(:name, :description, :event_set_id, :calendar_id, :all_day, :master_id, :url, :start, :finish, :venue_id, :venue_name)
    end

  end
end