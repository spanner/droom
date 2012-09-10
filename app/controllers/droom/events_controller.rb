class EventsController < Droom::EngineController
  require "uri"
  require "ri_cal"
  respond_to :json, :rss, :ics, :html
  
  before_filter :numerical_parameters

  # delivers designated lists of events in minimal formats

  def index
    @seen_events = {}
    @events = find_events
    respond_with @events
  end
  
  def show
    @event = Event.find(params[:id])
    respond_with @event
  end
  
  ### helper methods
  
  def period
    return @period if @period
    this = Date.today
    if params[:mday]
      start = Date.civil(params[:year] || this.year, params[:month] || this.month, params[:mday])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_day)
    elsif params[:month]
      start = Date.civil(params[:year] || this.year, params[:month])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_month)
    elsif params[:year]
      start = Date.civil(params[:year])
      @period = CalendarPeriod.between(start, start.to_datetime.end_of_year)
    end
  end
    
  def find_events
    ef = Event.scoped({})
    if period
      if period.bounded?
        ef = ef.between(period.start, period.finish) 
      elsif period.start
        ef = ef.after(period.start) 
      else
        ef = ef.before(period.finish) 
      end
    else
      ef = ef.future
    end
    ef = ef.approved if Radiant::Config['event_calendar.require_approval']
    ef = ef.in_calendars(calendars) if calendars
    ef
  end
  
  def continuing_events
    return @continuing_events if @continuing_events
    if period && period.start
      @continuing_events = Event.unfinished(period.start).by_end_date
    else
      @continuing_events = Event.unfinished(Time.now).by_end_date
    end
  end
  
protected
    
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
