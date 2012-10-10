module Droom
  class VenuesController < Droom::EngineController
    respond_to :json, :html
  
    before_filter :get_venues

    def index
      respond_with @venues
    end
    
    def show
      respond_with @venue
    end
    
  protected
  
    def get_venues
      @venues = Venue.all
    end

    def get_venues
      @venue = Venue.find(params[:id])
      @events = @venue.events.future_and_current
    end

  end
end