module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "ri_cal"
    respond_to :json, :rss, :ics, :html
  
    before_filter :authenticate_user!  
    before_filter :numerical_parameters
    before_filter :get_events
    before_filter :get_continuing_events, :only => :index
    
    # delivers designated lists of events in minimal formats

    def index
      respond_with @events
    end
  
    def personal
      @events = current_user.events
    end
  
    def show
      @event = Event.find(params[:id])
      respond_with @event
    end
  
    ### helper methods
  
    
  protected
    
    def get_events
      @events = Event.scoped({})
      if period
        if period.bounded?
          @events = @events.between(period.start, period.finish) 
        elsif period.start
          @events = @events.after(period.start) 
        else
          @events = @events.b@eventsore(period.finish) 
        end
      else
        @events = @events.future
      end
    end
  
    def get_continuing_events
      return @continuing_events if @continuing_events
      if period && period.start
        @continuing_events = Event.unfinished(period.start).by_end_date
      else
        @continuing_events = Event.unfinished(Time.now).by_end_date
      end
    end
  
    def period
      return @period if @period
      this = Date.today
      if params[:mday]
        start = Date.civil(params[:year] || this.year, params[:month] || this.month, params[:mday])
        @period = Droom::Period.between(start, start.to_datetime.end_of_day)
      elsif params[:month]
        start = Date.civil(params[:year] || this.year, params[:month])
        @period = Droom::Period.between(start, start.to_datetime.end_of_month)
      elsif params[:year]
        start = Date.civil(params[:year])
        @period = Droom::Period.between(start, start.to_datetime.end_of_year)
      end
    end

    # months can be passed around either as names or numbers
    # any date part can be 'now' or 'next' for ease of linking
    # and everything is converted to_i to save clutter later
  
    def numerical_parameters
      if params[:month] && month_names.include?(params[:month].titlecase)
        params[:month] = month_names.index(params[:month].titlecase)
      end
      [:year, :month, :mday].select{|p| params[p] }.each do |p|
        params[p] = Date.today.send(p) if params[p] == 'now'
        params[p] = (Date.today + 1.send(p == :mday ? :day : p)).send(p) if params[p] == 'next'
        params[p] = params[p].to_i
      end
    end
    
  end
end