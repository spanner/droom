module Droom
  class DroomRecord < ActiveRecord::Base
    include Droom::Concerns::ChangesNotified
    include Droom::Folders    # TODO please can we get rid of this now?
    self.abstract_class = true

    scope :other_than, -> these {
      these = [these].flatten
      where.not(id: these.map(&:id))
    }

  end
end