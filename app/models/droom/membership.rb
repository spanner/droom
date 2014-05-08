module Droom
  class Membership < ActiveRecord::Base
    belongs_to :user
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    has_one :mailing_list_membership, :dependent => :destroy

    after_create :link_folder
    after_create :create_mailing_list_membership
    after_create :create_invitations
    after_create :create_permissions

    after_destroy :unlink_folder
    after_destroy :destroy_invitations
    after_destroy :destroy_permissions
    after_destroy :destroy_similar
    
    accepts_nested_attributes_for :user

    # validates :user, :presence => true
    # validates :group, :presence => true

    scope :of_group, -> group {
      where(["group_id = ?", group.id])
    }

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
      self.all.each { |m| m.send :create_mailing_list_membership }
    end

  protected

    def link_folder
      user.add_personal_folders(group.folder)
    end

    def unlink_folder
      user.remove_personal_folders(group.folder) if user
    end
    
    def create_mailing_list_membership
      self.mailing_list_membership = Droom::MailingListMembership.where(address: user.email, listname: group.mailing_list_name).first_or_create
    end

    def create_invitations
      group.group_invitations.each do |gi|
        gi.create_personal_invitation_for(user)
      end
    end

    def create_permissions
      group.group_permissions.each do |gp|
        gp.create_permission_for(user)
      end
    end

    def destroy_invitations
      group.group_invitations.each do |gi|
        gi.invitations.for_user(user).destroy_all
      end
    end

    def destroy_permissions
      group.group_permissions.each do |gp|
        gp.user_permissions.for_user(user).destroy_all
      end
    end

    # it's possible to end up with multiple similar membership objects: here we
    # assume that when one is deleted, all should be.
    def destroy_similar
      group.memberships.where(:user_id => user.id).destroy_all
    end

  end
end
