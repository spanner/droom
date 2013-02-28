module Droom
  class CalendarsController < Droom::EngineController
    respond_to :html, :json, :rss, :ics
    layout :no_layout_if_pjax

    before_filter :authenticate_user!
    before_filter :get_calendar, :only => :show
    before_filter :get_calendars, :only => :index
    before_filter :require_admin!, :except => :show

    def show
      respond_with @calendar
    end

    def index
      respond_with @calendars
    end

  protected

    def get_calendars
      @calendars = Droom::Calendar.all
    end

    def get_calendar
      @calendar = Droom::Calendar.find(params[:id])
    end
  end
end