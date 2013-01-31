# This class has the awkward job of giving access to the mailing list membership records stored in
# legacy mailman mysql tables. They're likely to be held in another database, and they have an extremely
# un-rails-like schema, so our main job is to translate column values between their and our conventions.
#
# This whole mechanism and its configuration requirements can be ignored until you set 
# `Droom.enable_mailing_lists` to true in an initializer.
#
## Requirements:
# 
# ### Mailman data held in MySQL tables with the 'flat' data structure
#
# Mysql storage is considered modern and a bit racy by the mailman community. It's not officially 
# supported until mailman 3 coalesces but if you speak any python it's easy to make it work with 2.x. 
# Two related sets of dusty patches are available here:
#
#   http://wiki.list.org/pages/viewpage.action?pageId=15564884
#
# and I've found the slightly less ancient version from rezo.net works well enough:
#
#   http://trac.rezo.net/trac/rezo/browser/Mailman
#
# Using the wide data structure leaves you open to un-debuggable reserved-word problems (calling your
# mailing list all@ can cost several days) and for other reasons we prefer flat anyway.
#
# ### An id column as primary key
#
# Strictly speaking we should define a composite primary key based on address & listname, but it's
# much easier just to add an auto_incrementing id column and make that the primary key. Mailman
# doesn't care. You probably also want to create a unique index on address/listname so that mailman
# gets the benefit and sees the expected behaviour.
#
# ### A membership_id column
#
# We could (and used to) twist Activerecord out of shape by defining associations with address and 
# listname primary keys to link mailing list memberships to people and groups, but again it's much
# easier just to hang the mailing list membership off the group membership and have it created and
# destroyed at the same time.
#
# Again, you probably want an index on that column. We're not going to try and migrate that for you.

module Droom
  class MailingListMembership < ActiveRecord::Base
    attr_accessible :address, :listname, :digest, :not_metoo, :nomail, :plain, :ack
    #
    ## Configuration
    #
    # The mailman database connection should be defined in the host app's config/database.yml as 
    # `mailman_development` or `mailman_production`. We require the 'flat' database structure so that
    # all our records are held in the same table. Switching tables is possible but nasty, and makes
    # it very difficult for a person to belong to more than one mailing list.
    #
    # Set `Droom.mailing_lists_active_by_default` if you want automatic active memberships when people
    # are added to droom groups.
    #
    establish_connection :"mailman_#{Rails.env}"
    set_table_name :mailman_mysql

    ## Associations
    #
    # Giving membership of a group will create a mailing list membership automatically, if droom is
    # configured to use mailing lists at all. The activity status of the created mlm depends on the
    # `Droom.mailing_lists_active_by_default` setting.
    #
    belongs_to :membership
    before_create :set_defaults
    
    validates :address, :uniqueness => {:scope => :listname}
  
    ## Translation
    #
    # Mailman's boolean columns are held as Y/N so we intervene to translate.
    #
    [:digest, :not_metoo, :nomail, :plain, :ack].each do |col|
      define_method(col) do
        read_attribute(col) == 'Y'
      end
      define_method("#{col}?") do
        read_attribute(col) == 'Y'
      end
      define_method("#{col}=") do |value|
        write_attribute(col, to_yesno(value))
      end
      define_method("#{col}_before_type_cast") do
        read_attribute(col) == 'Y' ? 1 : 0
      end
    end

  private

    def set_defaults
      self.bi_lastnotice = 0
      self.bi_date = 0
      self.ack = true
      self.nomail = !Droom.mailing_lists_active_by_default?
      self.digest = Droom.mailing_lists_digest_by_default?
      true
    end

    def to_yesno(value)
      (value && value != 0 && value != "0") ? 'Y' : 'N'
    end
  
  end
end