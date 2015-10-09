module Droom
  class AddressType < ActiveRecord::Base
    has_many :emails
    has_many :phones
    has_many :addresses

    validates :name, presence: true

    scope :meant_for, -> purpose {
      where("relevance IS NULL OR relevance = ?", purpose)
    }

    def self.for_selection(purpose=nil)
      types = self.order(:name)
      types = types.meant_for(purpose.to_s) if purpose
      types.map{|type| [type.name, type.id] }
    end

    def slug
      name.parameterize
    end

  end
end
