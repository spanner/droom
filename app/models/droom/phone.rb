module Droom
  class Phone < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('phone <> "" and phone IS NOT NULL')
    }
  end
end
