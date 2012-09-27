module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

  end
end