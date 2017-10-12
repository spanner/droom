module Droom
  class Phone < ApplicationRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('phone <> "" and phone IS NOT NULL')
    }
  end
end
