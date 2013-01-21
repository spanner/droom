module Droom
  class Group < ActiveRecord::Base
    attr_accessible :name, :leader_id, :description

    belongs_to :created_by, :class_name => Droom.user_class
    belongs_to :leader, :class_name => 'Person'

    has_folder #... and subfolders, soon

    has_many :group_invitations, :dependent => :destroy, :uniq => true
    has_many :events, :through => :group_invitations

    has_many :memberships, :dependent => :destroy
    has_many :people, :through => :memberships, :uniq => true
  
    has_many :document_attachments, :as => :attachee, :dependent => :destroy
    has_many :documents, :through => :document_attachments
  
    before_save :ensure_slug

    scope :visible_to, lambda { |person|
      if person
        select('droom_groups.*')
          .joins('INNER JOIN droom_memberships as dm on droom_groups.id = dm.group_id')
          .where(['dm.person_id = ?', person.id])
          .group('droom_groups.id')
      else
        where("1=0")
      end
    }

    scope :with_documents, 
      select("droom_groups.*")
        .joins("INNER JOIN droom_document_attachments ON droom_groups.id = droom_document_attachments.attachee_id AND droom_document_attachments.attachee_type = 'Droom::Group'")
        .group("droom_groups.id")

  
    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_groups.name like ?', fragment)
    }
    
    default_scope order("droom_groups.created_at ASC")
    
    def admit(person)
      self.people << person
    end
    
    def attach(doc)
      self.documents << doc
    end

    def membership_for(person)
      self.memberships.for(person).first
    end
    
    def invite_to(event)
      group_invitations.find_or_create_by_event_id(event.id)
    end
    
    def uninvite_from(event)
      group_invitation = group_invitations.find_by_event_id(event.id)
      group_invitation.invitations.to_event(event).each do |invitation|
        invitation.destroy!
      end
      group_invitation.destroy!
    end
    
    def as_suggestion
      {
        :type => 'group',
        :prompt => name,
        :value => name,
        :id => id
      }
    end
    
  protected
  
    def ensure_slug
      ensure_presence_and_uniqueness_of(:slug, name.parameterize)
    end
  end
end