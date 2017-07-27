module Droom
  class Address < ApplicationRecord
    include Droom::Concerns::AddressBookProperty
  end
end
