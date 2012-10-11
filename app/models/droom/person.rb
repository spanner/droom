# This has been pulled from the yearbook and simplified. Docs need updating to match.
require 'vcard'
module Droom
  class Person < ActiveRecord::Base
    attr_accessible :name, :forename, :email, :phone, :description, :user, :title, :invite_on_creation, :admin_user
    attr_accessor :invite_on_creation, :admin_user
    
    ### Associations
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships

    has_many :invitations, :dependent => :destroy
    has_many :events, :through => :invitations

    has_many :personal_documents, :dependent => :destroy
    # has_many :attachments, :through => :personal_documents
    # has_many :documents, :through => :attachments

    # The `user` is this person's administrative account for logging in and out and forgetting her password.
    # A person can be listed without ever having a user, and a user account can exist (for an administrator) 
    # without having a person.
    belongs_to :user, :class_name => Droom.user_class.to_s, :dependent => :destroy
    
    before_save :update_user
    after_save :invite_if_instructed

    # The data requirements are minimal, with the idea that the directory will be populated gradually.
    validates :name, :presence => true
    validates :email, :presence => true

    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_people.name like ?', fragment)
    }

    scope :not_in_group, lambda { |group|
      
    }

    ### Images
    #
    # The treatment here is very basic compared to the yearbook's uploader, but we might bring that across
    # if this starts to look like a useful directory resource.
    #
    has_attached_file :image, { 
      :styles => {:standard => "400x300#", :thumb => "100x100#"},
      :default_url => "/assets/person/nopicture_:style.png"
    }
  
    def image_url(style=:standard)
      image.url(style)
    end
  
    def identifier
      'person'
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

    # I don't think we're using this anywhere at the moment, but a JSON API will grow here. Other classes already make more use of 
    # JSON representation, eg institutions for mapping or tags for tagging.
    #
    def as_json(options={})
      {
        :id => id,
        :name => name,
        :title => title
      }
    end
      
    # *for_selection* returns a list of people in options_for_select format with which to populate a select box.
    # 
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end
    
    
    # We defer the creation and updating of personal documents until the person actually logs in over DAV. At that stage a call 
    # goes to person.gather_and_update_documents and the copying begins. It's not really ideal from a responsiveness point of view
    # but it saves a great deal of update hassle (and storage space).
    #
    # NB this will not recreate deleted files: we only look as far as the PersonalDocument object, not the file 
    # it would usually have. This is to allow people to delete files they don't want, without having them 
    # constantly recreated.
    #
    def gather_and_update_documents
      # first we force the creation of all relevant subfolders, so that the initial directory view is populated.
      create_and_update_dav_directories
      # then we create, or if relevant update, all of this person's documents. #todo: This will be a delayed job.
      attachments = Droom::DocumentAttachment.to_groups(groups) + Droom::DocumentAttachment.to_events(events)
      attachments.each do |att|
        att.create_or_update_personal_document_for(self)
      end
    end
    
    def create_and_update_dav_directories
      (events.with_documents + groups.with_documents).each do |associate|
        create_dav_directory(associate.slug)
      end
    end
    
    def create_dav_directory(name)
      FileUtils.mkdir_p(Rails.root + "#{Droom.dav_root}/#{self.id}/#{name}")
    end
    
    # If a personal version exists, we will return that since it may contain annotations or amendments.
    #
    def personal_or_generic_version_of(document)
      personal_version_of(document) || document
    end

    # But if there has been no DAV login there can be no personal version.
    #
    def personal_version_of(document)
      personal_documents.derived_from(document).first
    end

    # group_documents returns all those documents that have been attached to a group of which this person is a member.
    # These documents will not show up in the calendar (since they are not attached to an event) so it's often a useful list.
    #
    def group_documents
      groups.any? ? Droom::Document.attached_to_these_groups(groups) : []
    end
    



    def invite_to(event)
      invitations.find_or_create_by_event_id(event.id) if event
    end
    
    def admit_to(group)
      memberships.find_or_create_by_group_id(group.id) if group
    end
    
    
    # some magic glue to allow slightly indiscriminate use of user and person objects.
    
    def person
      self
    end
    
    def admin?
      user && user.admin?
    end
    
    def has_active_user?
      user && user.activated?
    end
    
    def has_invited_user?
      user && user.invited?
    end
    
    def has_admin_user?
      user && user.admin?
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
      ).to_s
    end
    
    def address?
      post_line1? && post_city
    end
    
    def to_vcf
      @vcard ||= Vpim::Vcard::Maker.make2 do |maker|
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
    
  protected
    
    def invite_if_instructed
      invite_user if invite_on_creation
    end
    
    # ### Administration & callbacks
    #
    # At some point we may want to create a user to log in and look after this person. 
    # This usually has the side effect of sending out a login invitation.
    #
    def invite_user
      unless self.user
        if self.name? && self.email?
          self.create_user(:forename => forename, :name => name, :email => email, :admin => admin_user)
          self.save
        end
      end
    end
  
    # For most purposes the user email address is left alone in case people have a public and a private address,
    # but it can happen that the user is created before the person record has an email address. In that case we 
    # want to set the user address when the person gets one.
  
    def update_user
      if self.user
        self.user.update_column(:email, self.email) if email_changed?
        self.user.update_column(:name, self.name) if name_changed?
        self.user.update_column(:forename, self.forename) if forename_changed?
      end
    end
        
  end
end

