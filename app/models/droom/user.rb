module Droom
  class User < ActiveRecord::Base
    attr_accessible :name, :forename, :email, :password, :password_confirmation, :admin, :newly_activated, :update_person_email
    has_one :person
    has_many :dropbox_tokens, :foreign_key => "created_by_id"
    has_many :preferences, :foreign_key => "created_by_id"
  
    devise :database_authenticatable,
           :encryptable,
           :recoverable,
           :rememberable,
           :trackable,
           :validatable,
           :token_authenticatable,
           :encryptor => :sha512
  
    before_create :ensure_authentication_token
    after_create :send_invitation

    attr_accessor :newly_activated, :update_person_email
  
    validates :password, :length => { :minimum => 6 }, :if => :password_required?
  
    # Password is not required on creation, contrary to the devise defaults.
    # Login is by token auth until a password is set.
    # Token is retained to allow ical subscription without login.
    def activated?
      activated_at? && activated_at < Time.now
    end
  
    def password_required?
      activated? && (!password.blank?)
    end
  
    # The new user (who to begin with has a dummy password) cannot log in until activated by token.
  
    def active_for_authentication?
      super && activated?
    end
  
    def inactive_message
      :inactive
    end

    def invited?
      invited_at? && invited_at < Time.now
    end

    def activate!
      self.activated_at = Time.now
      self.save(:validation => false)
    end
  
    def active_for_authentication?
      super && activated?
    end
  
    def after_token_authentication
      activate!
    end
  
    # Current user is pushed into here to make it available in models,
    # most pertinently the UserActionObserver that sets ownership before save.
    #
    def self.current
      Thread.current[:user]
    end
    def self.current=(user)
      Thread.current[:user] = user
    end

    def invitation
      self.ensure_authentication_token
      Droom::Mailer.invitation(self)
    end

    # Personal DAV repository is accessed via a DAV4rack endpoint but we have to take care of its creation and population.
    #
    def dav_root
      dav_path = Rails.root + "webdav/#{id}"
      Dir.mkdir(dav_path, 0600) unless File.exist?(dav_path)
      dav_path
    end
  
    def full_name
      [forename, name].compact.join(' ').strip
    end
  
    def dropbox_access_token
      if dt = dropbox_tokens.by_date.last
        dt.access_token
      end
    end
    
    
    
    
    ## Preferences
    #
    # User settings are held as an association with Preference objects, which are simple key:value pairs.
    # The keys are usually colon:separated for namespacing purposes, eg:
    #
    #   current_user.pref("email:enabled")
    #   current_user.pref("dropbox:enabled")
    #
    # Default settings are defined in Droom.user_defaults and can be defined in an initializer if the default droom
    # defaults are not right for your application.
    #
    def pref(key)
      if pref = preferences.find_by_key(key)
        pref.value
      else
        Droom.user_default(key)
      end
    end
    
    # Preferences are set in a simple key:value way, where key is usually a compound namespace designator:
    #
    #   current_user.set_pref("email:enabled", true)
    #
    def set_pref(key, value)
      preferences.find_or_create_by_key(key).set(value)
    end
    

  protected

    def send_invitation
      invitation.deliver unless activated?
    end
  
  end
end