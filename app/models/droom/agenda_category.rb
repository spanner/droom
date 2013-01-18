module Droom
  class AgendaCategory < ActiveRecord::Base
    attr_accessible :event_id, :category_id
    belongs_to :category
    belongs_to :event
    belongs_to :created_by, :class_name => Droom.user_class
    has_folder
  end
end
