module Droom
  class VenuesController < Droom::EngineController
    respond_to :json, :html
  
    before_filter :authenticate_user!  
    before_filter :get_current_person
    before_filter :get_venues, :only => ["index"]
    before_filter :get_venue, :only => [:show, :update]

    def index
      respond_with @venues do |format|
        format.json {
          render :json => @venues.to_json(:person => @person)
        }
      end
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
      @events = @venue.events.visible_to(@current_person).future_and_current
    end

  end
end