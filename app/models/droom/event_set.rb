module Droom
  class EventSet < ActiveRecord::Base
    belongs_to :created_by, :class_name => "User"
    has_many :events, :dependent => :nullify
  end
end