module Droom
  class Invitation < ActiveRecord::Base
    belongs_to :person
    belongs_to :event
    belongs_to :created_by, :class_name => "User"
  end
end