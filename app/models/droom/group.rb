module Droom
  class Group < ActiveRecord::Base
    attr_accessible :name, :leader_id, :description

    belongs_to :created_by, :class_name => 'User'
    belongs_to :leader, :class_name => 'Person'

    has_many :memberships, :dependent => :destroy
    has_many :people, :through => :memberships, :uniq => true
  
    has_many :document_attachments, :as => :attachee, :dependent => :destroy
    has_many :documents, :through => :document_attachments
  
    before_save :check_slug

    scope :with_documents, 
      select("droom_groups.*")
        .joins("INNER JOIN droom_document_attachments ON droom_groups.id = droom_document_attachments.attachee_id AND droom_document_attachments.attachee_type = 'Droom::Group'")
        .group("droom_groups.id")

    def admit(person)
      self.people << person
    end

    def membership_for(person)
      self.memberships.for(person).first
    end
    
    def invite_to(event)
      people.each do |person|
        person.invite_to(event)
      end
    end
  
  protected
  
    def check_slug
      ensure_presence_and_uniqueness_of(:slug, name.parameterize)
    end
  end
end