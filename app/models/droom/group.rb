module Droom
  class Group < ActiveRecord::Base
    attr_accessible :name, :leader_id, :description

    belongs_to :created_by, :class_name => "Droom::User"
    belongs_to :leader, :class_name => 'Person'

    has_folder

    has_many :group_invitations, :dependent => :destroy, :uniq => true
    has_many :events, :through => :group_invitations

    has_many :memberships, :dependent => :destroy
    has_many :people, :through => :memberships, :uniq => true

    before_validation :ensure_slug
    before_validation :ensure_mailing_list_name

    validates :slug, :uniqueness => true, :presence => true
    validates :mailing_list_name, :uniqueness => true, :presence => true

    searchable do
      text :name, :boost => 10, :stored => true
      text :description, :stored => true
    end

    handle_asynchronously :solr_index

    def self.highlight_fields
      [:name, :description]
    end

    scope :all_private, where("private = 1")
    scope :not_private, where("private <> 1 OR private IS NULL")
    scope :all_public, where("public = 1 AND private <> 1 OR private IS NULL")
    scope :not_public, where("public <> 1 OR private = 1)")

    scope :visible_to, lambda { |person|
      if person
        if person.admin?
          scoped({})
        else
          select('droom_groups.*')
            .joins('INNER JOIN droom_memberships as dm on droom_groups.id = dm.group_id')
            .where(['dm.person_id = ?', person.id])
            .group('droom_groups.id')
        end
      else
        where("1=0")
      end
    }

    scope :matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_groups.name like ?', fragment)
    }

    default_scope order("droom_groups.created_at ASC")

    def admit(person)
      self.people << person
    end

    def attach(doc)
      # self.documents << doc
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
    
    def invited_to?(event)
      group_invitations.to_event(event).any?
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

    def ensure_mailing_list_name
      ensure_presence_and_uniqueness_of(:mailing_list_name, slug)
    end
  end
end
