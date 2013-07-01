module Droom
  class CalendarsController < Droom::EngineController
    respond_to :html, :json, :rss, :ics
    layout :no_layout_if_pjax

    load_and_authorize_resource

    def show
      respond_with @calendar
    end

    def index
      respond_with @calendars
    end

  end
end