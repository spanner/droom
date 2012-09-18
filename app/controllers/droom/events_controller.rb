module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "ri_cal"
    respond_to :json, :rss, :ics, :html
  
    before_filter :authenticate_user!  
    before_filter :numerical_parameters
    before_filter :find_events
    
    def dashboard
      if current_user.person
        @my_future_events = current_user.person.events.future_and_current
        @my_past_events = current_user.person.events.past
        @other_events = Droom::Event.future_and_current.not_private.without_invitations_to(current_user.person)
      elsif current_user.admin?
        @all_events = Droom::Event.future
      else
        @all_events = Droom::Event.future.not_private.limit(10)
      end
      respond_with @my_future_events
    end

    def index
      respond_with @events
    end
    
    def search
      respond_with @events do |format|
        format.js { render :partial => 'droom/shared/search_results' }
      end
    end
  
    def show
      @event = Droom::Event.find(params[:id])
      respond_with @event do |format|
        format.ics {
          rical = RiCal.Calendar { |cal| cal.add_subcomponent(@event.as_ri_cal_event) }
          send_data rical.to_s, :filename => "#{@event.slug}.ics", :type => "text/calendar"
        }
      end
    end
    
    def new
      @event = Droom::Event.new(:start => Time.now)
    end
    
    def create
      
    end
    
    def edit
      
    end
    
    def update
      
    end
    
  protected
    
    def find_events
      @events = Event.scoped({})
      if period
        if period.bounded?
          @events = @events.between(period.start, period.finish) 
        elsif period.start
          @events = @events.after(period.start) 
        else
          @events = @events.before(period.finish) 
        end
      else
        @events = @events.future
      end

      unless params[:q].blank?
        @searching = true
        @events = @events.name_matching(params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @events.page(@page).per(@show)
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