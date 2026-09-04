module Droom
  class Email < Droom::DroomRecord
    include Droom::Concerns::AddressBookProperty

    before_validation { self.email = self.class.normalize(email) }

    scope :populated, -> {
      where("email <> '' and email IS NOT NULL")
    }

    def self.normalize(email)
      email.to_s.strip.downcase.presence
    end
  end
end
