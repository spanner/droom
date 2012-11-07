module Droom
  class VenuesController < Droom::EngineController
    respond_to :json, :html
  
    before_filter :get_venues, :only => ["index"]
    before_filter :get_venue, :only => [:show, :update]

    def index
      respond_with @venues
    end
    
    def show
      respond_with @venue
    end
    
    def update
      @venue.update_attributes(params[:venue])
      respond_with @venue
    end
    
  protected
  
    def get_venues
      @venues = Venue.all
    end

    def get_venue
      @venue = Venue.find(params[:id])
      if @person
        @events = @venue.events.visible_to(@person).future_and_current
      else
        @events = @venue.events.all_public.future_and_current
      end
    end

  end
end