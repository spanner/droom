module Droom
  class User < ActiveRecord::Base

    attr_accessible :name, :forename, :email, :password, :password_confirmation, :admin, :newly_activated, :update_person_email, :preferences_attributes, :confirm, :old_id, :remove_person
    has_one :person
    has_many :dropbox_tokens, :foreign_key => "created_by_id"
    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true

    validates :email, :uniqueness => true, :presence => true
    validates_format_of :email, :with => /@/
    validates :name, :presence => true
    # validates :password, :presence => true, :length => { :minimum => 6 }, :confirmation => true, :if => :password_required?

    receives_messages# :groups => [:unconfirmed, :personed, :administrative]
  
    devise :database_authenticatable,
           :encryptable,
           :recoverable,
           :rememberable,
           :trackable,
           :confirmable,
           :token_authenticatable,
           :encryptor => :sha512
  
    before_create :ensure_authentication_token  # provided by devise
    before_create :ensure_confirmation_token  # provided by devise

    attr_accessor :newly_activated, :update_person_email, :confirm, :remove_person
  
  
    scope :unconfirmed, where("confirmed_at IS NULL")
    scope :administrative, where(:admin => true)
  
    scope :personed, select("droom_users.*")
                  .joins("INNER JOIN droom_people as dp ON dp.user_id = droom_users.id")

    scope :unpersoned, select("droom_users.*")
                  .joins("LEFT OUTER JOIN droom_people as dp ON dp.user_id = droom_users.id")
                  .having("count(dp.id) = 0")
    
    scope :with_person_in_group, lambda { |group|
      group = group.id if group.is_a? Droom::Group
      select("droom_users.*")
        .joins("INNER JOIN droom_people as dp ON dp.user_id = droom_users.id")
        .joins("INNER JOIN droom_memberships as dm ON dp.id = dm.person_id")
        .where("dm.group_id" => group)
    }

    # Messaging groups are normally scopes passed through when receives_messages is called,
    # but anything will work that can be called on the class and return a set of instances.
    # Here we're overriding the getter so as to offer sending by group membership as well as
    # the usual scoping.
    #
    def self.messaging_groups
      unless @messaging_groups
        @messaging_groups = {
          :unconfirmed => lambda { Droom::User.unconfirmed},
          :personed => lambda { Droom::User.personed },
          :administrative => lambda { Droom::User.administrative }
        }
        Droom::Group.all.each do |group|
          @messaging_groups[group.slug.to_sym] = lambda { Droom::User.with_person_in_group(group.id) }
        end
      end
      @messaging_groups
    end

    def confirm=(confirmed)
      confirm! if confirmed
    end

    def remove_person=(boolean)
      if boolean
        p = Droom::Person.find(person.id)
        p.user = nil
        p.save!
      end
    end

    # Password is not required on creation, contrary to the devise defaults.
    def password_required?
      confirmed? && (!password.blank?)
    end

    def password_match?
      self.errors[:password] << "can't be blank" if password.blank?
      self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
      self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
      password == password_confirmation && !password.blank?
    end

    def is_person?(person)
      person == self.person
    end

    def organisation
      person.organisation if person
    end

    # Current user is pushed into here to make it available in models
    # such as the UserActionObserver that sets ownership before save.
    #
    def self.current
      Thread.current[:user]
    end
    def self.current=(user)
      Thread.current[:user] = user
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

    def dropbox_token
      unless @dropbox_token
        @dropbox_token = dropbox_tokens.by_date.last || 'nope'
      end
      @dropbox_token unless @dropbox_token == 'nope'
    end

    def dropbox_client
      dropbox_token.dropbox_client if dropbox_token
    end
    
    def privileged?
      admin? || person && person.privileged?
    end
    
    
    ## Preferences
    #
    # User settings are held as an association with Preference objects, which are simple key:value pairs.
    # The keys are usually colon:separated for namespacing purposes, eg:
    #
    #   current_user.pref("email:enabled?")
    #   current_user.pref("dropbox:enabled?")
    #
    # Default settings are defined in Droom.user_defaults and can be defined in an initializer if the default droom
    # defaults are not right for your application.
    #
    # `User#pref(key)` returns the **value** of the preference (whether set or default) for the given key. It is intended
    # for use in views:
    #
    #   - if current_user.pref("dropbox:enabled?")
    #     = link_to "copy to dropbox", dropbox_folder_url(folder)
    #
    def pref(key)
      if pref = preferences.find_by_key(key)
        pref.value
      else
        Droom.user_default(key)
      end
    end
    
    # `User#preference(key)` always returns a preference object and is used to build control panels. If no preference
    # is saved for the given key, we return a new (unsaved) one with that key and the default value.
    #
    def preference(key)
      pref = preferences.find_or_initialize_by_key(key)
      pref.value = Droom.user_default(key) unless pref.persisted?
      pref
    end
    
    # Setting preferences is normally handled either by the PreferencesController or by nesting preferences
    # in a user form. `User#set_pref` is a convenient console method but not otherwise used much. 
    #
    # Preferences are set in a simple key:value way, where key usually includes some namespacing prefixes:
    #
    #   user.set_pref("email:enabled", true)
    #
    def set_pref(key, value)
      preferences.find_or_create_by_key(key).set(value)
    end
    
    ## Email
    #
    # If using `msg`, this defines the variables available in message templates.
    #
    def for_email
      generate_confirmation_token! unless confirmation_token?
      {
        :informal_name => informal_name,
        :formal_name => formal_name,
        :forename => forename,
        :name => name,
        :email => email,
        :confirmation_url => Droom::Engine.routes.url_helpers.welcome_url(:id => self.id, :confirmation_token => self.confirmation_token, :host => ActionMailer::Base.default_url_options[:host]),
        :sign_in_url => Droom::Engine.routes.url_helpers.new_user_session_path(:host => ActionMailer::Base.default_url_options[:host]),
        :password_reset_url => Droom::Engine.routes.url_helpers.edit_user_password_url(:reset_password_token => self.reset_password_token, :host => ActionMailer::Base.default_url_options[:host])
      }
    end
    
    ## Omniauth package
    #
    # This is returned to the client application in the final stage of oauth authentication, and may be used to create
    # a new local account.
    
    def credentials(options={})
      {
        id: id,
        title: title,
        name: name,
        forename: forename,
        email: email,
        admin: admin?,
        image: thumbnail
      }
    end
    
    def thumbnail
      person.image.url(:icon) if person
    end

  end
end