# This has been pulled from the yearbook and simplified. Docs need updating to match.
require 'vcard'

module Droom
  class Person < ActiveRecord::Base
    attr_accessible :name, :forename, :email, :phone, :description, :user, :title, :invite_on_creation, :admin_user, :position, :post_line1, :post_line2, :post_city, :post_region, :post_code, :mobile, :dob, :organisation_id
    attr_accessor :invite_on_creation, :admin_user
    acts_as_list

    belongs_to :organisation
    belongs_to :created_by, :class_name => "Droom::User"
    has_many :organisations, :foreign_key => :owner_id

    ### Group memberships
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships
    has_many :mailing_list_memberships, :through => :memberships
    
    has_many :preferences, :dependent => :destroy, :foreign_key => :created_by_id
    accepts_nested_attributes_for :preferences

    # The data requirements are minimal, with the idea that the directory will be populated gradually.
    validates :name, :presence => true

    def admit_to(group)
      memberships.find_or_create_by_group_id(group.id) if group
    end
    
    def expel_from(group)
      memberships.of_group(group).destroy_all
    end

    def member_of?(group)
      group && memberships.of_group(group).any?
    end

    ### Event invitations
    #
    has_many :invitations, :dependent => :destroy
    has_many :events, :through => :invitations

    def invite_to(event)
      invitations.find_or_create_by_event_id(event.id) if event
    end
    
    def uninvite_from(event)
      invitations.to_event(event).destroy_all
    end

    def invited_to?(event)
      event && invitations.to_event(event).any?
    end

    ## Folder permissions
    #
    # To simplify the business of showing and listing documents, we have adopted the convention that all
    # documents live in a folder. Person accounts have links to those folders through the very thin
    # PersonalFolder joining class, and at the view level we only ever show folder and subfolder lists.
    # The only place we ever need a list of all the documents visible to this person is when searching, and
    # for that we use the Document.visible_to scope, usually by way of the #documents method defined below.
    #
    # Personal folders are created and destroyed along with invitations and memberships..
    #
    has_many :personal_folders
    has_many :folders, :through => :personal_folders

    def add_personal_folders(folders=[])
      self.folders << folders if folders
    end
    
    def remove_personal_folders(folders=[])
      self.folders.delete(folders) if folders
    end
    
    def documents
      Document.visible_to(self)
    end
    
    ## User accounts
    #
    # The `user` is this person's administrative account for logging in and out and forgetting her password.
    # A person can be listed without ever having a user, and a user account can exist (for an administrator) 
    # without having a person.
    belongs_to :user, :class_name => "Droom::User", :dependent => :destroy
    before_save :update_user

    after_create :invite_if_instructed

    scope :unusered, where("user_id IS NULL")
    scope :usered, where("user_id IS NOT NULL")

    # some magic glue to allow slightly indiscriminate use of user and person objects.
    
    def person
      self
    end
    
    def admin?
      user && user.admin?
    end

    def has_admin_user?
      user && user.admin?
    end


    ### Images
    #
    has_upload :image, 
               :geometry => "520x520#",
               :styles => {
                 :icon => "32x32#",
                 :thumb => "120x120#",
                 :precrop => "1200x1200^"
               }

    ## Scopes
    
    default_scope order("droom_people.#{Droom.people_sort}")

    scope :all_private, where("private = 1")
    scope :not_private, where("private <> 1 OR private IS NULL")
    scope :all_public, where("public = 1 AND private <> 1 OR private IS NULL")
    scope :not_public, where("public <> 1 OR private = 1)")

    searchable do
      text :name, :boost => 10, :stored => true
      text :forename, :boost => 10, :stored => true
      text :description, :stored => true
    end

    def self.highlight_fields
      [:name, :forename, :description]
    end

    scope :matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_people.name LIKE :f OR droom_people.forename LIKE :f OR droom_people.email LIKE :f OR droom_people.phone LIKE :f', :f => fragment)
    }
    
    # warning! won't work in SQLite.
    scope :visible_to, lambda { |person|
      if person
        select('droom_people.*')
          .joins('LEFT OUTER JOIN droom_memberships as dm1 on droom_people.id = dm1.person_id')
          .joins('LEFT OUTER JOIN droom_memberships as dm2 on dm1.group_id = dm2.group_id')
          .where(['(dm2.person_id = ?) OR (droom_people.private <> 1)', person.id])
          .group('droom_people.id')
      else
        all_public
      end
    }
    
    scope :personally_invited_to_event, lambda { |event|
      joins('LEFT OUTER JOIN droom_invitations on droom_people.id = droom_invitations.person_id').where('droom_invitations.group_invitation_id is null AND droom_invitations.event_id = ?', event.id)
    }







    

    def full_name
      [forename, name].compact.join(' ').strip
    end

    def formal_name
      [title, forename, name].compact.join(' ').strip
    end
    
    def informal_name
      if Droom.use_forenames
        forename
      else
        name
      end
    end

    # *for_selection* returns a list of people in options_for_select format with which to populate a select box.
    # 
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end


    





    
    
    
    
    # Snail is a library that abstracts away - as far as possible - the vagaries of international address formats. Here we map our data columns onto Snail's abstract representations so that they can be rendered into the correct format for their country.
    def address
      Snail.new(
        :line_1 => post_line1,
        :line_2 => post_line2,
        :city => post_city,
        :region => post_region,
        :postal_code => post_code,
        :country => post_country
      )
    end
    
    def address?
      post_line1? && post_city
    end
    
    def to_vcf
      @vcard ||= Vcard::Vcard::Maker.make2 do |maker|
        maker.add_name do |n|
          n.given = name || ""
        end
        maker.add_addr {|a| 
          a.location = 'home' # until we do this properly with multiple contact sets
          a.country = post_country || ""
          a.region = post_region || ""
          a.locality = post_city || ""
          a.street = "#{post_line1}, #{post_line2}"
          a.postalcode = post_code || ""
        }
        maker.add_tel phone { |t| t.location = 'home' } unless phone.blank?
        # maker.add_tel mobile { |t| t.location = 'cell' } unless mobile.blank?
        maker.add_email email { |e| t.location = 'home' }
      end
      @vcard.to_s
    end
    
    def self.vcards_for(people=[])
      people.map(&:vcf).join("\n")
    end
    
    def as_suggestion
      {
        :type => 'person',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def as_search_result
      {
        :type => 'person',
        :prompt => name,
        :value => name,
        :id => id
      }
    end

    def invitable?
      name? && email?
    end
    
    def invite!
      invite_user
    end

  protected
    
    def index
      Sunspot.index!(self)
    end
    
    def invite_if_instructed
      invite_user if invite_on_creation
    end
    
    # ### Administration & callbacks
    #
    # At some point we may want to create a user to log in and look after this person. 
    # This usually has the side effect of sending out a confirmation message.
    #
    def invite_user
      unless self.user
        if invitable?
          user = self.create_user(:forename => forename, :name => name, :email => email)
          self.save
        end
      end
      self.user
    end
  
    def update_user
      if self.user && self.user.persisted?
        self.user.update_column(:email, self.email) if email_changed?
        self.user.update_column(:name, self.name) if name_changed?
        self.user.update_column(:forename, self.forename) if forename_changed?
      end
    end
        
  end
end

