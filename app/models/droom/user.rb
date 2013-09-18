module Droom
  class User < ActiveRecord::Base
    validates :family_name, :presence => true
    validates :given_name, :presence => true
    validates :email, :uniqueness => true, :presence => true
    validates_format_of :email, :with => /@/

    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true
    
    ## Authentication
    #
    devise :database_authenticatable,
           :recoverable,
           :rememberable,
           :trackable,
           :confirmable,
           :encryptable,
           :token_authenticatable,
           :cocable,
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

    scope :unconfirmed, -> { where("confirmed_at IS NULL") }
    scope :administrative, -> { where(:admin => true) }

    scope :in_name_order, -> {
      order("family_name ASC, given_name ASC")
    }

    def as_json_for_coca(options={})
      Rails.logger.warn ">>> Doom::User.as_json_for_coca"
      ensure_uid
      ensure_authentication_token
      {
        uid: uid,
        authentication_token: authentication_token,
        title: title,
        given_name: given_name,
        family_name: family_name,
        chinese_name: chinese_name,
        email: email,
        permissions: permission_codes.join(','),
        image: thumbnail
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
    
    scope :in_group, -> group {
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
    
    scope :personally_invited_to_event, -> event {
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
    has_attached_file :image,
                      :default_url => ActionController::Base.helpers.image_path("droom/missing/:style.png"),
                      :styles => {
                        :standard => "520x520#",
                        :icon => "32x32#",
                        :thumb => "130x130#"
                      }

    def thumbnail
      image.url(:icon) if image?
    end
    
    
    # For suggestion box
    #
    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('droom_users.given_name LIKE :f OR droom_users.family_name LIKE :f OR droom_users.chinese_name LIKE :f OR droom_users.title LIKE :f OR droom_users.email LIKE :f OR droom_users.phone LIKE :f OR CONCAT(droom_users.given_name, " ", droom_users.family_name) LIKE :f OR CONCAT(droom_users.family_name, " ", droom_users.given_name) LIKE :f', :f => fragment)
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
    
    
    ## Names
    #
    # With Anglo-Chinese Hong Kong names it is difficult to be sure of the right presentation.
    #
    # We hold the name in three fields: title, given name and family name. People with both a Chinese and an
    # English forename are encouraged to enter their given name in the form Tai Wan, Jimmy. The family_name 
    # should always be a single, usually Chinese, surname: Chan or Smith.
    #
    # When a comma is found in the given name, we assume that they have followed the chinese, english format.
    # If not, we assume the whole name is Chinese.
    #
    # ### Polite informality
    #
    # People with an English forename would normally be addressed as Jimmy Chan. People with only a Chinese
    # forename should be addressed as Chan Tai Wan.
    #
    def informal_name
      # The standard form of the given name is Tai Wan, Ray
      chinese, english = given_name.split(/,\s*/)
      # But some people are known only as Ray.
      # Here we can't tell the difference between people with one chinese given name and one anglo given name
      # but the order of names is reversed in the latter case. For now we assume that the presence of a chinese
      # name indicates that the chinese word ordering should be used.
      unless chinese_name?
        english ||= chinese.split(/\s+/).first
      end
      if english
        # People with an english name are called Ray Chan, by default
        [english, family_name].join(' ')
      else
        # People without are called Chan Tai Wan
        [family_name, chinese].join(' ')
      end
    end
  
    def name
      chinese, english = given_name.split(/,\s*/)
      unless chinese_name?
        english ||= chinese.split(/\s+/).first
      end
      if english
        [english, family_name].join(' ')
      else
        [family_name, chinese].join(' ')
      end
    end

    # ### Formality
    #
    # The family name is held separately becaose for most purposes we will address people using the relatively 
    # reliable 'Dr Chan' or 'Mr Smith'.
    #
  
    def title
      title = read_attribute(:title)
      if title.blank?
        title = (gender == 'f') ? 'Ms' : 'Mr'
      end
      title
    end
  
    def formal_name
      [title, family_name].compact.join(' ')
    end

    # This is our best shot at a representation of how this person would normally be referred to. It combines
    # the informal name (which includes some logic to show chinese, anglo and mixed names correctly) with the title.
    #
    def colloquial_name
      [title, informal_name].compact.join(' ')
    end

    # ### Completeness
    #
    # For record-keeping purposes we show the whole name: Chan Tai Wan, Jimmy.
    #
    def full_name
      [family_name, given_name].compact.join(' ')
    end

    # ### Compatibility
    #
    # An HKID card will normally show only the translitered Chinese name: Chan Tai Wan
    #
    def official_name
      chinese, english = given_name.split(/,\s*/)
      [family_name, chinese].join(' ')
    end

    ## Addresses
    #
    # These will change soon to a simple text field with geolocation.
    #
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
          :unconfirmed => -> { Droom::User.unconfirmed},
          :administrative => -> { Droom::User.administrative }
        }
        Droom::Group.all.each do |group|
          @messaging_groups[group.slug.to_sym] = -> { Droom::User.in_group(group.id) }
        end
      end
      @messaging_groups
    end

    def for_email
      {
        :informal_name => informal_name,
        :formal_name => formal_name,
        :family_namne => family_name,
        :given_name => given_name,
        :chinese_name => chinese_name,
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
      permissions.map(&:slug).compact.uniq
    end
    
    def permitted?(key)
      permission_codes.include?(key)
    end


    ## Ownership
    #
    has_many :scraps, :foreign_key => "created_by_id"
    has_many :documents, :foreign_key => "created_by_id"



  protected

    def ensure_uid
      self.uid ||= SecureRandom.uuid
    end

  end
end