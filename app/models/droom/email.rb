module Droom
  class Email < ApplicationRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('email <> "" and email IS NOT NULL')
    }
  end
end
