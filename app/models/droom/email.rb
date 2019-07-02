module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    scope :populated, -> {
      where('email <> "" and email IS NOT NULL')
    }
  end
end
