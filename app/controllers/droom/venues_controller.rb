module Droom
  class VenuesController < Droom::EngineController
    respond_to :json, :html
  
    before_filter :get_venues

    def index
      respond_with @venues
    end
    
  protected
  
    def get_venues
      @venues = Venue.all
    end
  end
end