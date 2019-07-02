module Droom
  class Address < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('address <> "" and address IS NOT NULL')
    }

  end
end
