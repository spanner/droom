module Droom
  class DashboardController < Droom::EngineController
    respond_to :html, :js
    layout :normal_unless_pjax
  
    before_filter :authenticate_user!  
    
    def index
      render
    end
    
    def page
      
    end
    
  protected
  
    def normal_unless_pjax
      if request.headers['X-PJAX']
        false
      else
        Droom.layout
      end
    end
    
  end
end