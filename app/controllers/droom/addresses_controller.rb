# Address book data is always nested. Here we are only providing add-item form partials through #new.
#
module Droom
  class AddressesController < Droom::ApplicationController
    layout false
    load_resource :user, class: "Droom::User"
    load_and_authorize_resource through: :user
  end
end