module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "ri_cal"
    respond_to :json, :rss, :ics, :html, :js
    layout :normal_unless_pjax
  
    before_filter :authenticate_user!  
    before_filter :numerical_parameters
    before_filter :get_event, :only => [:show, :edit]
    before_filter :build_event, :only => [:new, :create]
    before_filter :find_events, :only => [:index]
    
    def dashboard
      if current_user.person
        @my_future_events = current_user.person.events.future_and_current
        @my_past_events = current_user.person.events.past
        @all_events = Droom::Event.future_and_current.not_private.without_invitations_to(current_user.person)
      elsif current_user.admin?
        @all_events = Droom::Event.future_and_current
      else
        @all_events = Droom::Event.future_and_current.not_private.limit(10)
      end
      respond_with @my_future_events
    end

    def index
      respond_with @events do |format|
        format.js {
          render :partial => 'droom/events/minicalendar'
        }
      end
    end
    
    def feed
      @events = Droom::Event.all
      respond_with @events
    end
    
    def show
      respond_with @event do |format|
        format.js {
          render :partial => 'droom/events/event'
        }
      end
    end
    
    def new
      respond_with @event
    end
    
    def create
      if @event.save
        render :show
      else
        render :new
      end
    end
    
    def edit
      
    end
    
    def update
      
    end
    
  protected
  
    def normal_unless_pjax
      if request.headers['X-PJAX']
        false
      else
        "application"
      end
    end
    
    def build_event
      params[:event] ||= {}
      @event = Droom::Event.new({:start => Time.now}.merge(params[:event]))
    end

    def get_event
      @event = Droom::Event.find(params[:id])
    end
    
    def find_events
      @events = Event.scoped({})  #todo: visible or personal scope
      today = Date.today
      year = params[:year] || today.year
      month = params[:month] || today.month
      mday = params[:mday] || today.mday
      datemarker = Date.civil(year, month, mday)
      
      if !params[:mday].blank?
        @events = @events.on_day(year, month, mday)
        @pagetitle = I18n.t(:events_on, :day => I18n.l(datemarker, :format => :natural))

      elsif !params[:month].blank?
        @events = @events.in_month(year, month)
        @pagetitle = I18n.t(:events_in, :period => I18n.l(datemarker, :format => :month))

      elsif !params[:year].blank?
        @events = @events.in_year(year)
        @pagetitle = I18n.t(:events_in, :period => I18n.l(datemarker, :format => :year))

      else
        @pagetitle = I18n.t(:future_events)
      end
      
      unless params[:q].blank?
        @events = @events.name_matching(params[:q])
        @pagetitle << I18n.t(:matching, :term => params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @events.page(@page).per(@show)
    end
    

    # months can be passed around either as names or numbers
    # any date part can be 'now' or 'next' for ease of linking
    # and everything is converted to_i to save clutter later
    def month_names
      ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    end
  
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