module Droom
  class Address < ActiveRecord::Base
    belongs_to :user
    belongs_to :address_type
    after_save :undefault_others

    scope :default, -> {
      where(default: true)
    }

    scope :other_than, -> address {
      where.not(id: address.id)
    }

    def undefault_others
      if user && self.default?
        user.addresses.other_than(self).update_all(default: false)
      end
    end
  end
end
