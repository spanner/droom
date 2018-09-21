module Droom
  class CalendarsController < Droom::ApplicationController
    respond_to :html, :json, :rss, :ics
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def show
      respond_with @calendar
    end

    def index
      respond_with @calendars
    end

  protected
  
    def calendar_parameters
      params.require(:calendar).permit(:events_private, :documents_private)
    end

  end
end