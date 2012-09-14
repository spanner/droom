module Droom
  class EngineController < ::ApplicationController
    helper Droom::DroomHelper
    rescue_from "Droom::DroomErrorFound", :with => :rescue_bang
  
  protected

    def rescue_bang
      render :text => 'bang'
    end
    
  end
end