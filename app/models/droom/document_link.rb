# the links between a person and document are too various and too extended to make them
# easy to retrieve in a single query. Instead we maintain an index of person-document links.

module Droom
  class DocumentLink < ActiveRecord::Base
    attr_accessible :person, :document_attachment
    belongs_to :person
    belongs_to :document_attachment
    has_one :personal_document, :dependent => :destroy
        
    def ensure_personal_document
      create_personal_document unless personal_document?
    end
    
    def self.repair
      Droom::Person.each do |person|
        person.repair_document_links
      end
    end
  end
end