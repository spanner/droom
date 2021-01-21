module Droom
  class Noticeboard < Droom::DroomRecord
    include Droom::Concerns::Slugged

    has_many :scraps

    before_validation :slug_from_name

    def self.for_selection
      self.all.map{|c| [c.name, c.id] }
    end

  end
end
