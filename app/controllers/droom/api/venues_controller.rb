module Droom::Api
  class VenuesController < Droom::Api::ApiController

    before_filter :get_venues, only: [:index]
    before_filter :build_venue, only: [:create]
    load_and_authorize_resource
    after_filter :set_pagination_headers, only: [:index]
    
    def index
      render json: @venues.includes(:awards, :notes)
    end

    def show
      render json: @venue
    end

    def update
      @venue.update_attributes(venue_params)
      render json: @venue
    end

    def create
      @venue.update_attributes(venue_params)
      render json: @venue
    end

    def destroy
      @venue.destroy
      head :ok
    end

  protected

    def find_person
      @venue = Droom::Venue.where(uid: params[:id]).first
      raise ActiveRecord::RecordNotFound unless @venue
    end
    
    def build_venue
      @venue = Droom::Venue.new
    end

    def get_venues
      venues = Droom::Venue.in_name_order
      
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| venues = venues.matching(frag) }
      end

      @show = params[:show] || 20
      @page = params[:page] || 1
      if @show == 'all'
        @venues = venues
      else
        @venues = venues.page(@page).per(@show) unless 
      end
    end

    def venue_params
      params.require(:venue).permit(:name, :lat, :lng, :address, :post_code, :country_code)
    end

  end
end