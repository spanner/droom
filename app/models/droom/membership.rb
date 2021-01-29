module Droom
  class Membership < Droom::DroomRecord
    belongs_to :user
    belongs_to :group
    belongs_to :created_by, optional: true, class_name: "Droom::User"

    has_one :mailing_list_membership, :dependent => :destroy

    after_create :create_mailing_list_membership
    after_create :create_permissions

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
    
    def create_mailing_list_membership
      self.mailing_list_membership = Droom::MailingListMembership.where(address: user.email, listname: group.mailing_list_name).first_or_create
    end

    def create_permissions
      group.group_permissions.each do |gp|
        gp.create_permission_for(user)
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
