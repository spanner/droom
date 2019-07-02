module Droom
  class EventSet < Droom::DroomRecord
    belongs_to :created_by, :class_name => "User"
    has_many :events, :dependent => :nullify
  end
end