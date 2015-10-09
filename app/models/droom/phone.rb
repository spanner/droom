module Droom
  class Phone < ActiveRecord::Base
    belongs_to :user
    belongs_to :address_type
    after_save :undefault_others

    scope :default, -> {
      where(default: true)
    }

    scope :other_than, -> phone {
      where.not(id: phone.id)
    }

    def undefault_others
      if user && self.default?
        user.phones.other_than(self).update_all(default: false)
      end
    end
  end
end
