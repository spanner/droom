# The DroomAuth::User class is provided by our user-information service, which at the moment
# can either be Droom::Auth (for local user data) or Droom::Auth::Client (for deference to a
# remote authentication service presumably running Droom::Auth).
#
# Droom::User adds a lot of associations to other Droom data classes and a few lifecycle calls.
# The remote auth service doesn't need all this.
#
module Droom
  class User < DroomAuth::User

    ## Owned objects
    # Newer classes have a user_id, older still use created_by_id.
    #
    has_many :events, :foreign_key => "created_by_id"
    has_many :scraps, :foreign_key => "created_by_id"
    has_many :documents, :foreign_key => "created_by_id"
    has_many :pages
    has_many :images
    has_many :videos


    ## Organisation affiliation
    #
    belongs_to :organisation
    before_save :org_admin_if_alone

    def org_admin?
      organisation && organisation_admin?               #TODO admin of _this_ organisation would require join with attributes, and UI support.
    end

    def external?
      !organisation || organisation.external?
    end

    def internal?
      organisation && !organisation.external?
    end


    ## Group memberships
    #
    has_many :memberships, :dependent => :destroy
    has_many :groups, :through => :memberships
    has_many :mailing_list_memberships, :through => :memberships

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
      memberships.of_group(group.id).first()
    end


    ## Event invitations
    #
    has_many :invitations, :dependent => :destroy

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


    ## Names
    #
    def title_ordinary?
      ['Mr', 'Ms', 'Mrs', '', nil].include?(title)
    end

    def title_if_it_matters
      title unless title_ordinary?
    end

    def informal_name
      [given_name, family_name].join(' ')
    end
    alias :name :informal_name

    def formal_name
      if title_ordinary?
        informal_name
      else
        [title, family_name].join(' ')
      end
    end

    def colloquial_name
      [title_if_it_matters, informal_name].compact.join(' ')
    end

    def full_name
      [given_name, family_name].compact.join(' ')
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


    ## Preferences
    #
    # User settings are held as an association with Preference objects, which are simple key:value pairs.
    # The keys are usually colon:separated for namespacing purposes, eg:
    #
    #   current_user.pref("email:enabled?")
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
    has_many :preferences, :foreign_key => "created_by_id"
    accepts_nested_attributes_for :preferences, :allow_destroy => true

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


    ## Search
    #
    # Overrides the standard DroomAuth search to add more droom data.
    #
    def search_data
      data = {
        uid: uid,
        title: title,
        name: name,
        chinese_name: chinese_name,
        emails: emails.map(&:email),
        addresses: addresses.map(&:address),
        organisation: organisation_id,
        organisation_name: organisation_name,
        phones: phones.map(&:phone),
        groups: group_slugs,
        liveliness: liveliness,
        privileged: privileged?
      }
      data.merge(additional_search_data)
    end

    def group_slugs
      groups.pluck(:slug).map(&:presence).compact.uniq
    end

    def organisation_name
      organisation.name if organisation
    end

    def organisation_tags
      organisation.tags if organisation
    end

    def confirm_account
      if confirmed_at.nil?
        'No'
      else
        'Yes'
      end
    end

    def status
      if admin?
        'admin'
      elsif privileged?
        'senior'
      elsif data_room_user?
        'internal'
      else
        'external'
      end
    end

    def liveliness
      if emails.empty?
        'unreachable'
      elsif !last_sign_in_at? and !confirmed_at?
        'unresponsive'
      elsif data_room_user?
        'internal'
      else
        'external'
      end
    end

    def additional_search_data
      {}
    end


    protected

    def org_admin_if_alone
      if organisation && organisation.users.length == 1
        self.organisation_admin = true
      end
    end

  end
end
