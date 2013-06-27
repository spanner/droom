module Droom
  class Resource < ActiveRecord::Base
    attr_accessible :name
    has_many :permissions, :dependent => :destroy
  end
end