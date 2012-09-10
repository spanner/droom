# This has been pulled from the yearbook and simplified. Docs need updating to match.

module Droom
  class Person < ActiveRecord::Base
  
    ### Associations
    #
    # 'Groups' are the usual means of invitation to events or access to documents. 
    has_many :memberships
    has_many :groups, :through => :groups

    # Documents can be attached to most things
    has_many :attachments, :as => :attachee
    has_many :documents, :through => :attachments

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
    before_save :read_upload
  
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
  
    # Invitation is handled by the user class, along with all the other account management toil,
    # but from an administrator's point of view it makes sense to think of inviting the listed person,
    # so here we pass the message on.
    #
    def invite!
      create_user unless user
      user.invite!
    end
  
    # An invited person has a user object and the user has been sent an invitation. She may or may not 
    # have received it or activated the account.
    #
    scope :invited, joins("INNER JOIN users on users.person_id = people.id").where("users.invited_at IS NOT NULL")
    scope :uninvited, joins("INNER JOIN users on users.person_id = people.id").where("users.invited_at IS NULL")
    scope :uninvitable, where("people.email IS NULL OR people.email = ''")
  
    def invited?
      self.user && self.user.invited?
    end
  
    def invited_at
      self.user.invited_at if self.user
    end
  
    scope :active, joins("INNER JOIN users on users.person_id = people.id").where("users.activated = 1")
    scope :inactive, joins("INNER JOIN users on users.person_id = people.id").where("users.activated = 0")
  
    def activated?
      self.user && self.user.activated?
    end
    
    # *for_selection* returns a list of people in options_for_select format with which to populate a select box.
    # 
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end

  private

    # ### Administration & callbacks
    #
    # *read_upload* is called before_save. If there is a new upload, or any of our scale and crop values are changed, it will assign 
    # the upload file to the person image. Even if it's the same image as before, the effect is to trigger post-processing again
    # and apply the new crop and scale values.
    #
    def read_upload
      self.image = self.image_upload.file if self.image_upload && (self.image_upload_id_changed? || self.image_scale_width_changed? || self.image_offset_top_changed? || self.image_offset_left_changed?)
    end
  
    # On creation we must create a user object too. This has the side effect of sending out a login invitation.
    #
    def create_user
      unless self.user
        if self.name? && self.email?
          self.build_user(:preferred_name => [self.title, self.name].join(' '), :email => self.email).save(:validation => false)
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
    
    def invite_user
      if send_invitation?
        create_user
        user.invite!
      end
    end
    
  end
end