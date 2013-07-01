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

  end
end