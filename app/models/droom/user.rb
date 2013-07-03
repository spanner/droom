module Droom
  class User < ActiveRecord::Base

    attr_accessible :uid, :title, :name, :forename, :email, :password,  :password_confirmation, :phone, :description, :admin, :preferences_attributes, :confirm, :old_id, :invite_on_creation, :post_line1, :post_line2, :post_city, :post_region, :post_country, :post_code, :mobile, :dob, :organisation_id, :public, :private, :female, :image_file_name, :image_file_size, :image_updated_at, :image_upload_id, :image_scale_width, :image_scale_height, :image_offset_left, :image_offset_top
    
    validates :name, :presence => true
    validates :email, :uniqueness => true, :presence => true
    validates_format_of :email, :with => /@/

    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true
    
    ## Authentication
    #
    devise :database_authenticatable,
           :encryptable,
           :recoverable,
           :rememberable,
           :trackable,
           :confirmable,
           :token_authenticatable,
           :encryptor => :sha512
    
    before_create :ensure_authentication_token
    before_create :ensure_uid
    after_create :invite_if_instructed

    def password_required?
      confirmed? && (!password.blank?)
    end

    def password_match?
      self.errors[:password] << "can't be blank" if password.blank?
      self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
      self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
      password == password_confirmation && !password.blank?
    end

    scope :unconfirmed, where("confirmed_at IS NULL")
    scope :administrative, where(:admin => true)

    def serializable_hash(options={})
      {
        uid: uid,
        authentication_token: authentication_token,
        title: title,
        name: name,
        forename: forename,
        email: email,
        image: thumbnail,
        permissions: permission_codes.join(',')
      }
    end

    ## Organisation affiliation
    #
    belongs_to :organisation
    has_many :organisations, :foreign_key => :owner_id

    ## Group memberships
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships
    has_many :mailing_list_memberships, :through => :memberships

    def admit_to(group)
      memberships.find_or_create_by_group_id(group.id) if group
    end
    
    def expel_from(group)
      memberships.of_group(group).destroy_all
    end

    def member_of?(group)
      group && memberships.of_group(group).any?
    end
    
    def membership_of(group)
      memberships.find_by_group_id(group.id)
    end
    
    scope :in_group, lambda { |group|
      group = group.id if group.is_a? Droom::Group
      select("droom_users.*")
        .joins("INNER JOIN droom_memberships as dm ON droom_users.id = dm.user_id")
        .where("dm.user_id" => group)
    }

    ## Event invitations
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
      event && !!invitation_to(event)
    end
    
    def invitation_to(event)
      invitations.to_event(event).first
    end
    
    scope :personally_invited_to_event, lambda { |event|
      joins('LEFT OUTER JOIN droom_invitations on droom_users.id = droom_invitations.user_id').where('droom_invitations.group_invitation_id is null AND droom_invitations.event_id = ?', event.id)
    }

    ## Folder permissions
    #
    # To simplify the business of showing and listing documents, we have adopted the convention that all
    # documents live in a folder. User accounts have links to those folders through the very thin
    # PersonalFolder joining class, and at the view level we only ever show folder and subfolder lists.
    # The only place we ever need a list of all the documents visible to this person is when searching, and
    # for that we use the Document.visible_to scope, usually by way of the #documents method defined below.
    #
    # Personal folders are created and destroyed along with invitations and memberships.
    #
    has_many :personal_folders
    has_many :folders, :through => :personal_folders

    def add_personal_folders(folders=[])
      self.folders << folders if folders
    end
    
    def remove_personal_folders(folders=[])
      self.folders.delete(folders) if folders
    end
    
    def has_folder?(folder)
      folder && personal_folders.of_folder(folder).any?
    end
    
    def documents
      Document.visible_to(self)
    end


    ## Dropbox links
    #
    has_many :dropbox_tokens, :foreign_key => "created_by_id"
    has_many :dropbox_documents
    
    def dropbox_token
      unless @dropbox_token
        @dropbox_token = dropbox_tokens.by_date.last || 'nope'
      end
      @dropbox_token unless @dropbox_token == 'nope'
    end

    def dropbox_client
      dropbox_token.dropbox_client if dropbox_token
    end
    

    ## Mugshot
    #
    has_upload :image, 
               :geometry => "520x520#",
               :styles => {
                 :icon => "32x32#",
                 :thumb => "130x130#",
                 :precrop => "1200x1200<"
               }

    def thumbnail
      image.url(:icon) if image?
    end
    
    
    # For suggestion box
    #
    scope :matching, lambda { |fragment| 
      fragment = "%#{fragment}%"
      where('droom_users.name LIKE :f OR droom_users.forename LIKE :f OR droom_users.email LIKE :f OR droom_users.phone LIKE :f OR CONCAT(droom_users.forename, " ", droom_users.name) LIKE :f', :f => fragment)
    }
    
    def as_suggestion
      {
        :type => 'person',
        :prompt => formal_name,
        :value => formal_name,
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
    
    
    # For select box
    #
    def self.for_selection
      self.published.map{|p| [p.name, p.id] }
    end
    
    
    # Names and addresses
    
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
        maker.add_tel mobile { |t| t.location = 'cell' } unless mobile.blank?
        maker.add_email email { |e| t.location = 'home' }
      end
      @vcard.to_s
    end
    
    def self.vcards_for(users=[])
      users.map(&:vcf).join("\n")
    end


    ## Messaging
    #
    # Messaging groups are normally scopes passed through when receives_messages is called,
    # but anything will work that can be called on the class and return a set of instances.
    # Here we're overriding the getter so as to offer sending by group membership as well as
    # the usual scoping.
    #
    
    receives_messages
    
    def self.messaging_groups
      unless @messaging_groups
        @messaging_groups = {
          :unconfirmed => lambda { Droom::User.unconfirmed},
          :administrative => lambda { Droom::User.administrative }
        }
        Droom::Group.all.each do |group|
          @messaging_groups[group.slug.to_sym] = lambda { Droom::User.in_group(group.id) }
        end
      end
      @messaging_groups
    end

    def for_email
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


    # ### Invitation
    #
    def invite_if_instructed
      invite! if invite_on_creation?
    end
    
    def invite_on_creation?
      !!invite_on_creation && invite_on_creation != 0 && invite_on_creation != "0"
    end
    
    def invite!
      self.send_confirmation_instructions
    end
    
    def invited?
      !!self.confirmation_sent_at
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
    
    ## Permissions
    #
    # Permissions are usually assigned by way of group membership, but the effect of this is to create a user-permission
    # object. Additional user-permission objects can be created: all we need to do here is return that set.
    
    has_many :user_permissions
    has_many :permissions, :through => :user_permissions
    
    def permission_codes
      permissions.map(&:slug)
    end
    
    def permitted?(key)
      permission_codes.include?(key)
    end


    ## Ownership
    #
    # Current user is pushed into here to make it available in models
    # such as the UserActionObserver that sets ownership before save.
    #
    def self.current
      Thread.current[:user]
    end
    def self.current=(user)
      Thread.current[:user] = user
    end
     
  protected

    def ensure_uid
      self.uid ||= SecureRandom.uuid
    end

  end
end