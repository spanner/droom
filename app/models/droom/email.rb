module Droom
  class Email < ActiveRecord::Base
    include Droom::Concerns::AddressBookProperty
  end
end
