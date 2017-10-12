module Droom
  class Address < ApplicationRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('address <> "" and address IS NOT NULL')
    }

  end
end
