module Droom
  class AgendaCategoriesController < Droom::ApplicationController
    respond_to :html, :js
    layout :no_layout_if_pjax

    load_and_authorize_resource :event
    load_and_authorize_resource :agenda_category, :through => :event

  protected
  
    def agenda_category_parameters
      params.require(:agenda_category).permit(:event_id, :category_id)
    end
    
  end
end
