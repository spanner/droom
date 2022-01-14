module Droom
  class VenuesController < Droom::DroomController
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
      @venue.update(params[:venue])
      respond_with @venue
    end

  protected
  
    def venue_params
      params.require(:venue).permit(:name, :lat, :lng, :address, :post_code, :country_code)
    end

  end
end