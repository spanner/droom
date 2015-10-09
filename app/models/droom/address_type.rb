module Droom
  class AddressType < ActiveRecord::Base
    has_many :emails
    has_many :phones
    has_many :addresses

    validates :name, presence: true

    scope :not_phones, -> {
      where(phones_only: false)
    }

    def self.for_selection
      self.order(:name).map{|type| [type.name, type.id] }
    end

    def self.for_selection_without_phone_types
      self.not_phones.order(:name).map{|type| [type.name, type.id] }
    end

    def slug
      name.parameterize
    end

  end
end
