# This has been pulled from the yearbook and simplified. Docs need updating to match.
require 'vcard'
module Droom
  class Person < ActiveRecord::Base
    attr_accessible :name, :forename, :email, :phone, :description, :user, :title, :invite_on_creation, :admin_user, :position
    attr_accessor :invite_on_creation, :admin_user
    acts_as_list
    ### Associations
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships

    has_many :invitations, :dependent => :destroy
    has_many :events, :through => :invitations

    # document_links is an automatically maintained index that we use to make easier the task of retrieving
    # the documents this person is allowed to see.
    has_many :document_links, :dependent => :destroy
    has_many :document_attachments, :through => :document_links
    # is this association really needed? We always retrieve the document list using the visible_to scope, so as to get public docs too.
    has_many :documents, :through => :document_attachments, :uniq => true
    
    # personal documents are the document clones created when a user logs to her DAV folder.
    # they are spun off the document links
    has_many :personal_documents, :through => :document_links

    # The `user` is this person's administrative account for logging in and out and forgetting her password.
    # A person can be listed without ever having a user, and a user account can exist (for an administrator) 
    # without having a person.
    belongs_to :user, :class_name => Droom.user_class.to_s, :dependent => :destroy
    
    before_save :update_user
    after_save :invite_if_instructed

    # The data requirements are minimal, with the idea that the directory will be populated gradually.
    validates :name, :presence => true
    
    default_scope order("droom_people.#{Droom.people_sort}")

    scope :name_matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_people.name like ?', fragment)
    }
    
    scope :visible_to, lambda { |person|
      select('droom_people.*')
        .joins('LEFT OUTER JOIN droom_memberships as dm1 on droom_people.id = dm1.person_id')
        .joins('LEFT OUTER JOIN droom_memberships as dm2 on dm1.group_id = dm2.group_id')
        .where(['droom_people.public = 1 OR droom_people.public = "t" OR dm2.person_id = ?', person.id])
        .group('droom_people.id')
    }
    
    scope :personally_invited_to_event, lambda { |event|
      joins('LEFT OUTER JOIN droom_invitations on droom_people.id = droom_invitations.person_id').where('droom_invitations.group_invitation_id is null AND droom_invitations.event_id = ?', event.id)
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

    # Document links function as a lookup table to speed up the process of working out what this person can see.
    # They are created when an attachment, invitation or membership confers access, and destroyed when a link in  
    # that chain is removed.
    #
    # This will rebuild the document_link index for this person.
    #
    def repair_document_links
      # NB this will also destroy all our personal documents. Very much a last resort.
      self.document_links.destroy_all
      group_and_event_attachments.each do |da|
        document_links.create(:document_attachment => da)
      end
    end
    
    def group_and_event_attachments
      Droom::DocumentAttachment.to_groups(groups) + Droom::DocumentAttachment.to_events(events)
    end

    # We defer the creation and updating of personal documents until the person actually logs in over DAV. At that stage a call 
    # goes to person.create_personal_documents and the copying begins. It's not really ideal from a responsiveness point of view
    # but it saves a great deal of update hassle (and storage space).
    #
    # NB this will not recreate deleted files: we only look as far as the PersonalDocument object, not the file 
    # it would usually have. This is to allow people to delete files they don't want, without having them 
    # constantly recreated.
    #
    def create_personal_documents
      create_and_update_dav_directories
      document_links.each { |dl| dl.ensure_personal_document }
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
    
    def uninvite_from(event)
      p "-> destroying invitations: #{invitations.to_event(event).inspect}"
      invitations.to_event(event).destroy_all
    end
    
    def admit_to(group)
      memberships.find_or_create_by_group_id(group.id) if group
    end
    
    def expel_from(group)
      memberships.of_group(group).destroy_all
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
      )
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

