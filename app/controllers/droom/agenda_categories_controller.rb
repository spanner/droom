module Droom
  class AgendaCategoriesController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :get_event
    before_filter :get_agenda_category, :only => [:destroy, :edit, :update]
    before_filter :build_agenda_category, :only => [:new, :create]

  protected

    def get_event
      @event = Droom::Event.find(params[:event_id])
    end

    def get_agenda_category
      @agenda_category = @event.agenda_categories.find(params[:id])
    end
    
    def build_agenda_category
      @agenda_category = @event.agenda_categories.build(params[:agenda_category])
    end

  end
end
