# This migration comes from droom (originally 20130131161430)
class MailingLists < ActiveRecord::Migration
  def change
    # One option for mailing list configuration is to point mailman at this table.
    # The other, much more likely, is to define a mailman_production environment 
    # and point it at your existing mailman database.
    #
    create_table :droom_mailing_list_memberships do |t|
      t.integer :membership_id
      t.string :address
      t.string :listname
      t.string :hide              # These should all be enum(Y,N) really
      t.string :nomail            # since we're mimicking a cranky old
      t.string :ack               # mailman table, but this should work.
      t.string :not_metoo         #
      t.string :digest            #
      t.string :plain             #
      t.string :one_last_digest   #
      t.string :password
      t.string :lang
      t.string :name
      t.integer :user_options
      t.integer :delivery_status
      t.string :topics_userinterest
      t.string :topics_userinterest
      t.datetime :delivery_status_timestamp
      t.string :bi_cookie
      t.string :bi_score
      t.string :bi_noticesleft
      t.date :bi_lastnotice
      t.date :bi_date
    end
    add_index :droom_mailing_list_memberships, :membership_id
    add_index :droom_mailing_list_memberships, [:address, :listname]
    
    add_column :droom_groups, :mailing_list_name, :string
  end
end
