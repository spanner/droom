module Droom
  class Address < ActiveRecord::Base
    include Droom::Concerns::AddressBookProperty
  end
end
