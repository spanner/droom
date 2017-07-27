module Droom
  class Email < ApplicationRecord
    include Droom::Concerns::AddressBookProperty
  end
end
