module Droom
  class Membership < ActiveRecord::Base
    attr_accessible :group_id, :person_id

    belongs_to :person
    belongs_to :group
    belongs_to :created_by, :class_name => "User"

    has_one :mailing_list_membership, :dependent => :destroy

    after_create :link_folder
    after_create :make_mailing_list_membership
    after_destroy :unlink_folder
    
    validates :person, :presence => true
    validates :group, :presence => true

    scope :of_group, lambda { |group|
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
      if Droom.enable_mailing_lists?
        self.mailing_list_membership = Droom::MailingListMembership.find_or_create_by_address_and_listname(person.email, group.mailing_list_name)
      end
    end

  end
end
