module Droom
  class EngineController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    helper Droom::DroomHelper
  end
end