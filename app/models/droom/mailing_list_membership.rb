# This class has the awkward job of giving access to the mailing list membership records stored in
# legacy mailman mysql tables. They're likely to be held in another database, and they have an extremely
# un-rails-like schema, so our main job is to translate between their and our conventions.
#
# This whole mechanism and its configuration requirements can safely be ignored unless you want to 
# use it, in which case you should set `Droom.enable_mailing_lists` to true in an initializer and read on.
#
# If you don't set `enable_mailing_lists` then some database activity will still go on, but with no
# consequence, and the mailing list interface controls will not appear.
#
## Requirements
# 
# The MailingListMembership class is able to interface directly with your existing mailman data, with 
# the addition of a couple of columns to support activerecord associations. It's mostly just a case of 
# configuring access to the old data.
# 
# ### Mailman data held in MySQL tables with the 'flat' data structure
#
# There are two options here. Either you can use the standard table that has already been created here, 
# or you can define a `mailman_[env]` connection in database.yml that points to an external mailman
# database. In that case see the notes below about adding a couple of columns.
#
# ### Mailman configured to use MySQL
#
# If you don't have an existing mailmanmysql setup, it takes a few steps to point your mailman installation 
# at this database and table. It can be done either globally or on a per-list basis, so it is possible
# to keep your existing mailman installation but add a new database-backed mailing list.
#
# Mysql storage is considered modern and a bit racy in the mailman community, having only been available
# since the early 2000s.  It's not officially supported until mailman 3 coalesces out of the ether but if 
# you speak any python it's easy to make it work with 2.x. Two sets of dusty patches are available here:
#
#   http://wiki.list.org/pages/viewpage.action?pageId=15564884
#
# and I've found the slightly less ancient version from rezo.net works well:
#
#   http://trac.rezo.net/trac/rezo/browser/Mailman
#
# In order that we can store membership of different lists in the same table, please make sure that
# mailman is using the 'flat' data structure. If you want to enable mysql just for selected lists,
# put an `extend.py` in each list directory and leave the rest of your configuration as it is.
#
# It is currently a good idea to avoid reserved words in your mailing list names. They'll work in rails 
# but not in python, where the quoting of some database queries seems to be less than perfect.
#
# ### Minor changes to the mailman table
#
# The local table is already set up in a way that should work equally well with rails and mailman. 
# If you're using a remote mailman table, it will need a couple of small changes:
#
# **An id column as primary key.** Strictly speaking we should define a composite primary key based 
# on address & listname, but it's much easier just to add an auto_incrementing id column and make 
# that the primary key. Mailman doesn't care as long as its columns are there. You probably also want
# to create a unique index on address+listname so that mailman gets the benefit and sees the expected 
# behaviour.
#
# **A membership_id column** We could (and used to) twist Activerecord out of shape by defining 
# associations with address and listname primary keys between mailing list memberships and people 
# and groups, but again it's much easier just to belong_to a group membership. For that we need a 
# membership_id column. Again, you will want an index on that column.

module Droom
  class MailingListMembership < Droom::DroomRecord
    #
    ## Configuration
    #
    # A dedicated mailman database connection can be defined in the host app's config/database.yml as 
    # `mailman_development` or `mailman_production` if you want us to use an existing mailman database. 
    # We can only work with the 'flat' database structure, where all the list memberships are held in 
    # one table.
    #
    # If no such connection is defined, we will use the local `droom_mailing_list_memberships` table.
    #
    begin
      establish_connection :"mailman_#{Rails.env}"
      set_table_name Droom.mailman_table_name
    rescue ActiveRecord::AdapterNotSpecified
      Rails.logger.warn "Droom: No mailman connection configured. Using #{Rails.env} database."
    end

    ## Associations
    #
    # Giving membership of a group will create a mailing list membership automatically. 
    # The activity status of the created mlm depends on the `Droom.mailing_lists_active_by_default` 
    # setting, and its effect depends of course on your mailman setup.
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
      (value && value != 0 && value != "0" && value != "N") ? 'Y' : 'N'
    end
  
  end
end