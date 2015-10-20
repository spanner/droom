module Droom
  class User < ActiveRecord::Base
    validates :family_name, :presence => true
    validates :given_name, :presence => true
    # validates :email, :uniqueness => true, :presence => true
    validates :uid, :uniqueness => true, :presence => true

    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true
    
    ## Authentication
    #
    devise :database_authenticatable,
           :cookie_authenticatable,
           :recoverable,
           :trackable,
           :confirmable,
           :rememberable,
           :reconfirmable => false
    
    before_validation :ensure_uid!
    before_save :ensure_authentication_token
    after_save :send_confirmation_if_directed
    after_save :confirmed_if_password_set

    # People are often invited into the system in batches or after offline contact.
    # set user.defer_confirmation to a true or call user.defer_confirmation! +before saving+
    # if you want to create a user account without sending out any messages yet.
    #
    # When you do want to invite that person, call user.resend_confirmation_token or
    # set the send_confirmation flag on a save.
    #
    # defer_confirmation is also set by remote services that send out their own invitations,
    # eg. when a new user is invited to screen an application round.
    #
    attr_accessor :defer_confirmation, :send_confirmation, :confirming

    # send_confirmation_notification? is called by devise's immediate confirmation mechanism.
    # If the defer_confirmation flag has been set as usual, we postpone.
    #
    def send_confirmation_notification?
      super && really_send_confirmation?
    end

    def really_send_confirmation?
      !defer_confirmation?
    end

    def defer_confirmation!
      self.defer_confirmation = true
    end

    def defer_confirmation?
      defer_confirmation && defer_confirmation != "false"
    end
    
    # send_confirmation? is called after save by our own later confirmation mechanism.
    # If the send_confirmation flag has been set, we confirm.
    #
    def send_confirmation!
      self.send_confirmation = true
    end

    def send_confirmation?
      send_confirmation && send_confirmation != "false"
    end

    def active_for_authentication?
      true
    end
    
    # Only invoke password-confirmation validation when a password is being set.
    #
    def password_required?
      confirmed? && (!password.blank?)
    end
    
    def password_set?
      encrypted_password?
    end
    
    def lacks_password?
      !password_set?
    end
    
    ## Session ID
    #
    # Allows us to invalidate a session by remote control when the user signs out on a satellite site.
    
    def reset_session_id!
      token = generate_authentication_token
      self.update_column(:session_id, token)
      token
    end
    
    def clear_session_id!
      self.update_column(:session_id, "")
    end

    # Tell devise to tell warden to salt the session cookie with our session_id.
    # If the session_id changes, eg due to remote logout, the session will no longer succeed in describing a user.
    def authenticatable_salt
      session_id
    end

    ## Auth tokens
    #
    # Are no longer native to devise but we use them for domain-cookie auth.
    
    def authenticate_token(token)
      Devise.secure_compare(self.authentication_token, token)
    end

    def reset_authentication_token!
      token = generate_authentication_token
      self.update_column(:authentication_token, token)
      token
    end
    
    def ensure_authentication_token
      if authentication_token.blank?
        self.authentication_token = generate_authentication_token
      end
      authentication_token
    end
    
    def confirmed=(value)
      self.confirmed_at = Time.now if value.present? and value != "false"
    end

    def password_match?
      self.errors[:password] << "can't be blank" if password.blank?
      self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
      self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
      password == password_confirmation && !password.blank?
    end

    # Our old user accounts store passwords as salted sha512 digests. Current best practice uses BCrypt
    # so we migrate user accounts across in this rescue block whenever we hear BCrypt grumbling about the old hash.
  
    def valid_password?(password)
      begin
        super(password)
      rescue BCrypt::Errors::InvalidHash
        Rails.logger.warn "...trying sha512 on password input"
        stretches = 10
        salt = self.password_salt
        pepper = nil
        old_digest = Devise::Encryptable::Encryptors::Sha512.digest(password, stretches, salt, pepper)
        if old_digest == self.encrypted_password   
          self.password = password
          self.save
          return true
        else
          # Doesn't match the old format either: password is just wrong.
          return false
        end
      end
    end 
    
    scope :unconfirmed, -> { where("confirmed_at IS NULL") }
    scope :administrative, -> { where(:admin => true) }
    scope :this_month, -> { where("created_at > ?", Time.now - 1.month) }
    scope :this_week, -> { where("created_at > ?", Time.now - 1.week) }
    
    scope :in_name_order, -> {
      order("family_name ASC, given_name ASC")
    }

    ## Organisation affiliation
    #
    belongs_to :organisation
    has_many :organisations, :foreign_key => :owner_id

    ## Group memberships
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships
    has_many :mailing_list_memberships, :through => :memberships

    scope :in_any_directory_group, -> {
      joins(:groups).where(droom_groups: {directory: true}).group("droom_users.id")
    }

    def admit_to(groups)
      groups = [groups].flatten
      groups.each do |group|
        memberships.where(group_id: group.id).first_or_create
      end
    end
    
    def expel_from(group)
      memberships.of_group(group).destroy_all
    end

    def member_of?(group)
      group && memberships.of_group(group).any?
    end
    
    def membership_of(group)
      memberships.find_by(group_id: group.id)
    end
    
    scope :in_group, -> group {
      group = group.id if group.is_a? Droom::Group
      select("droom_users.*")
        .joins("INNER JOIN droom_memberships as dm ON droom_users.id = dm.user_id")
        .where("dm.group_id" => group)
    }

    ## Event invitations
    #
    has_many :invitations, :dependent => :destroy
    has_many :events, :through => :invitations

    def invite_to(event)
      invitations.where(event_id: event.id).first_or_create if event && invitable?
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
    
    def invitable?
      email?
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

    do_not_validate_attachment_file_type :image

    def thumbnail
      image.url(:thumb) if image?
    end
    
    def icon
      image.url(:icon) if image?
    end
 
    # For suggestion box
    #
    scope :matching, -> fragment {
      where('droom_users.given_name LIKE :f OR droom_users.family_name LIKE :f OR droom_users.chinese_name LIKE :f OR droom_users.title LIKE :f OR droom_users.email LIKE :f OR droom_users.phone LIKE :f OR CONCAT(droom_users.given_name, " ", droom_users.family_name) LIKE :f OR CONCAT(droom_users.family_name, " ", droom_users.given_name) LIKE :f', :f => "%#{fragment}%")
    }
    
    scope :matching_in_col, -> col, fragment {
      where("droom_users.#{col} LIKE :f", :f => "%#{fragment}%")
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
        english ||= chinese.strip.split(/\s+/).first
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
    
    def title_ordinary?
      ['Mr', 'Ms', 'Mrs', '', nil].include?(title)
    end
    
    def title_if_it_matters
      title unless title_ordinary?
    end
  
    def title
      title = read_attribute(:title)
      if title.blank?
        title = (gender == 'f') ? 'Ms' : 'Mr'
      end
      title
    end
    
    # This should be a reasonable formal first-person form of address.
    #
    def formal_name
      [title, family_name].join(' ')
    end

    # This is our best shot at a representation of the usual third person form of this person's name. It combines
    # the informal name (which includes some logic to show chinese, anglo and mixed names correctly) with the title,
    # if the title is not ordinary.
    #
    def colloquial_name
      [title_if_it_matters, informal_name].compact.join(' ')
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
      if pref = preferences.find_by(key: key)
        pref.value
      else
        Droom.user_default(key)
      end
    end

    def pref?(key)
      !!pref(key)
    end

    # `User#preference(key)` always returns a preference object and is used to build control panels. If no preference
    # is saved for the given key, we return a new (unsaved) one with that key and the default value.
    #
    def preference(key)
      pref = preferences.where(key: key).first_or_initialize
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
      preferences.where(key: key).first_or_create.set(value)
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

    def permission_codes=(codes)
      #TODO
    end

    def permitted?(key)
      permission_codes.include?(key)
    end

    def permissions_elsewhere?
      permission_codes.select{|pc| pc !~ /droom/}.any?
    end

    def data_room_user?
      !Droom.require_login_permission || admin? || permitted?('droom.login')
    end

    ## Other ownership
    #
    has_many :scraps, :foreign_key => "created_by_id"
    has_many :documents, :foreign_key => "created_by_id"

  protected
  
    def ensure_uid!
      self.uid = SecureRandom.uuid unless self.uid?
    end
    
    def send_confirmation_if_directed
      unless confirming
        # a slightly rubbish way to avoid the double hit caused by devise updating the confirmation token.
        self.confirming = true
        self.send_confirmation_instructions if email? && send_confirmation?
      end
    end

    def confirmed_if_password_set
      self.update_column(:confirmed_at, Time.now) if password_set? && !confirmed?
    end

  private
  
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end

  end
end