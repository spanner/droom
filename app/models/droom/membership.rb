module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    has_one :mailing_list_membership, :dependent => :destroy

    after_create :link_folder
    after_create :make_mailing_list_membership
    after_create :update_person_status
    after_create :create_invitations
    after_destroy :unlink_folder
    after_destroy :update_person_status
    after_destroy :destroy_invitations
    
    validates :person, :presence => true
    validates :group, :presence => true

    scope :of_group, lambda { |group|
      where(["group_id = ?", group.id])
    }
    
    scope :privileged, select('droom_memberships.*')
                         .joins('inner join droom_groups as dg on droom_memberships.group_id = dg.id')
                         .where('dg.privileged' => true)
                         .group('droom_memberships.id')

    def current?
      expires and expires > Time.now
    end

    def set_expiry(date)
      unless expires and expires > date
        self.expires = date
        save!
      end
    end
    
    # This is sometimes useful if a configuration change means we're looking at a different mailman table.
    #
    def self.repair_mailing_list_memberships
      self.all.each { |m| m.send :make_mailing_list_membership }
    end

  protected

    def link_folder
      person.add_personal_folders(group.folder)
    end

    def unlink_folder
      person.remove_personal_folders(group.folder)
    end

    def unlink_folder
      person.remove_personal_folders(group.folder)
    end
    
    def make_mailing_list_membership
      self.mailing_list_membership = Droom::MailingListMembership.find_or_create_by_address_and_listname(person.email, group.mailing_list_name)
    end

    def update_person_status
      person.send :update_status
    end

    def create_invitations
      group.group_invitations.each do |gi|
        gi.create_personal_invitation_for(person)
      end
    end

    def delete_invitations
      group.group_invitations.each do |gi|
        gi.invitations.for_person(person).destroy_all
      end
    end

  end
end
