module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    rescue_from "Droom::DroomErrorFound", :with => :rescue_bang
  
  protected

    def rescue_bang
      render :text => 'bang'
    end
    
    def no_layout_if_pjax
      if request.headers['X-PJAX']
        false
      else
        Droom.layout
      end
    end
    
  end
end