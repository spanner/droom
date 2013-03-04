module Droom
  class AgendaCategory < ActiveRecord::Base
    attr_accessible :event_id, :category_id
    belongs_to :category
    belongs_to :event
    belongs_to :created_by, :class_name => "Droom::User"
    has_folder :within => :event
    accepts_nested_attributes_for :category
    
    validates :event, :presence => true
    validates :category, :presence => true
    
    delegate :slug, :to => :category
  end
end
