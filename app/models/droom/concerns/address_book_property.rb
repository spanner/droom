module Droom::Concerns::AddressBookProperty
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    belongs_to :address_type, optional: true
    after_save :undefault_others

    scope :preferred, -> {
      order(default: :desc).limit(1)
    }

    scope :by_preference, -> {
      order(default: :desc)
    }

    scope :default, -> {
      where(default: true)
    }

    scope :of_type, -> name {
      joins(:address_type).where(droom_address_types: {name: name})
    }

  end

  def undefault_others
    if user && self.default?
      self.class.where(user_id: user.id).other_than(self).update_all(default: false)
    end
  end

  def address_type_name
    address_type.name if address_type
  end

end
