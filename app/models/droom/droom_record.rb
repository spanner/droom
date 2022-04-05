module Droom
  class DroomRecord < ActiveRecord::Base
    include Droom::Concerns::ChangesNotified
    include Droom::Folders    # TODO please can we get rid of this now?
    self.abstract_class = true
  end
end