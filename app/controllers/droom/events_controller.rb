module Droom
  class EventsController < Droom::EngineController
    require "uri"
    require "ri_cal"
    respond_to :json, :rss, :ics, :html, :js, :zip
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!  
    before_filter :require_admin!, :except => [:index, :show]
    before_filter :numerical_parameters
    before_filter :get_person
    before_filter :get_event, :only => [:show, :edit, :update, :destroy]
    before_filter :build_event, :only => [:new, :create]
    before_filter :find_events, :only => [:index, :calendar]
    
    def index
      respond_with @events do |format|
        format.js {
          render :partial => 'droom/events/events'
        }
      end
    end
    
    def calendar
      respond_with @events do |format|
        format.js {
          render :partial => 'droom/events/calendar'
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
        format.zip { 
          send_file @event.documents_zipped.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@event.slug}.zip"
        }
      end
    end
    
    def new
      respond_with @event
    end
    
    def create
      if @event.save
        render :partial => "created"
      else
        respond_with @event
      end
    end
    
    def edit
      
    end
    
    def update
      @event.update_attributes(params[:event])
      if @event.save
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
    
    def get_person
      @person = Droom::Person.find(params[:person_id]) unless params[:person_id].blank?
    end
    
    def build_event
      params[:event] ||= {}
      @event = Droom::Event.new({:start => Time.now}.merge(params[:event]))
    end

    def get_event
      @event = Droom::Event.find(params[:id])
    end
    
    def find_events
      @events = @person ? @person.events : Event.scoped({})  #todo: visible or personal scope
      today = Date.today
      year = params[:year] || today.year
      month = params[:month] || today.month
      mday = params[:mday] || today.mday
      datemarker = Date.civil(year, month, mday)
      
      @events = @events.future_and_current
      
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