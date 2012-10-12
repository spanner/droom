module Droom
  class Invitation < ActiveRecord::Base
    attr_accessible :event_id, :person_id
    
    belongs_to :person
    belongs_to :event
    belongs_to :group_invitation
    belongs_to :created_by, :class_name => "User"

  end
end