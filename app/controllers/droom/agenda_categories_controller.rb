module Droom
  class AgendaCategoriesController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax

    load_and_authorize_resource :event
    load_and_authorize_resource :agenda_category, :through => :event

  end
end
