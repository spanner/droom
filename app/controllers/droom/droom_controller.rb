module Droom
  class DroomController < ActionController::Base
    include Droom::Concerns::ControllerHelpers
    helper Droom::DroomHelper
    helper ApplicationHelper
  end
end
