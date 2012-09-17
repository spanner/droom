module Droom
  class AgendaSection < ActiveRecord::Base
    attr_accessible :code, :name, :description, :event
    
    belongs_to :created_by, :class_name => 'User'
    belongs_to :event
    has_many :document_attachments
    
    default_scope order("droom_agenda_sections.name ASC")
  end
end
