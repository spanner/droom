# This has been pulled from the yearbook and simplified. Docs need updating to match.

module Droom
  class Person < ActiveRecord::Base
    attr_accessible :name, :email, :phone, :description, :user_id
  
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
    belongs_to :user, :dependent => :destroy
    before_save :update_user

    # The data requirements are minimal, with the idea that the directory will be populated gradually.
    validates :name, :presence => true
    validates :email, :presence => true

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

    def formal_name
      [title, name].join(' ')
    end
      
    # *for_selection* returns a list of people in options_for_select format with which to populate a select box.
    # 
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end
    
    # The usual way to delivery personal documents to a Person is to call `gather_documents_from(event or group)` 
    # on the creation of an invitation or a membership. 
    #
    def gather_documents_from(attachee)
      attachee.document_attachments.each do |att|
        self.personal_documents.create(:document_attachment => att)
      end
    end
    
    # but it is also possible to scan through all our associated events and groups and to create new personal 
    # documents for any that do not already have them.
    # NB this will not recreate deleted files: we only look as far as the PersonalDocument object, not the file 
    # it would usually have. This is to allow people to delete files they don't want, without having them 
    # constantly recreated.
    #
    def gather_new_documents
      new_attachments = Droom::Attachment.to_groups(groups).not_personal_for(self) + Droom::Attachment.to_events(events).not_personal_for(self)
      new_attachments.each do |att|
        att.create_personal_document(:person => self)
      end
    end
    
    
    
    
    def invite_to(event)
      events << event
    end
    
    def admit_to(group)
      groups << group
    end
    
    
  private

    # ### Administration & callbacks
    #
    # On creation we must create a user object too. This has the side effect of sending out a login invitation.
    #
    def create_user
      unless self.user
        if self.name? && self.email?
          self.build_user(:name => [self.title, self.name].join(' '), :email => self.email).save(:validation => false)
        end
      end
    end
  
    # For most purposes the user email address is left alone in case people have a public and a private address,
    # but it can happen that the user is created before the person record has an email address. In that case we 
    # want to set the user address when the person gets one.
  
    def update_user
      if self.user && !self.user.email
        self.user.update_person_email = false
        self.user.update_column(:email, self.email)
      end
    end
        
  end
end