module Droom
  class VenuesController < Droom::EngineController
    respond_to :json, :html

    load_and_authorize_resource

    def index
      respond_with @venues do |format|
        format.json {
          render :json => @venues.to_json(:user => @user)
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
  
    def venue_params
      params.require(:venue).permit(:name, :lat, :lng, :post_line1, :post_line2, :post_city, :post_country, :post_code, :old_id)
    end

  end
end