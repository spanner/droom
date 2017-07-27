module Droom
  class Phone < ApplicationRecord
    include Droom::Concerns::AddressBookProperty
  end
end
