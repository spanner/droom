require 'searchkick'

module Droom
  class DroomRecord < ActiveRecord::Base
    include Droom::Folders
    self.abstract_class = true
  end
end