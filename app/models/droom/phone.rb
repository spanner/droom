module Droom
  class Phone < ActiveRecord::Base
    include Droom::Concerns::AddressBookProperty
  end
end
