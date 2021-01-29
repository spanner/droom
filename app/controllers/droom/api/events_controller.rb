module Droom::Api
  class EventsController < Droom::Api::ApiController

    before_action :get_events, only: [:index]
    before_action :find_or_create_event, only: [:create]
    load_and_authorize_resource find_by: :uuid, class: "Droom::Event"
    
    def index
      render json: @events
    end

    def show
      render json: @event
    end

    def update
      @event.update(event_params)
      render json: @event
    end

    def create
      if @event && @event.persisted?
        render json: @event
      else
        render json: {
          errors: @event.errors.to_a
        }
      end
    end

    def destroy
      @event.destroy
      head :ok
    end

  protected

    def find_or_create_event
      if params[:event]
        if params[:event][:uid].present?
          @event = Droom::Event.where(uid: params[:event][:uid]).first
        end
      end
      @event ||= Droom::Event.create(event_params)
    end

    def get_events
      events = Droom::Event.in_name_order
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| events = events.matching(frag) }
      end
      @events = events
    end

    def event_params
      params.require(:event).permit(:name, :description, :event_set_id, :calendar_id, :all_day, :url, :start, :finish, :timezone, :venue_id, :venue_name)
    end

  end
end