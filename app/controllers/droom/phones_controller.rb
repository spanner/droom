# Address book data is always nested. Here we are only providing add-item form partials through #new.
#
module Droom
  class PhonesController < Droom::EngineController
    layout false
    load_resource :user
    load_and_authorize_resource through: :user
  end
end