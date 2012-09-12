# This migration comes from droom (originally 20120910075016)
class CreateDroomData < ActiveRecord::Migration
  def change
    create_table :droom_events do |t|
      t.datetime :start
      t.datetime :finish
      t.string :name
      t.text :description
      t.string :url
      t.integer :event_set_id
      t.integer :venue_id
      t.integer :created_by_id
      t.string :uuid
      t.boolean :all_day
      t.integer :master_id
      t.timestamps
    end
    add_index :droom_events, :event_set_id
    add_index :droom_events, :master_id

    create_table :droom_documents do |t|
      t.string :name
      t.text :description
      t.attachment :file
      t.integer :created_by_id
      t.timestamps
    end

    create_table :droom_people do |t|
      t.string :name
      t.string :title
      t.string :email
      t.string :phone
      t.text :description
      t.attachment :image
      t.integer :user_id
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_people, :email
    add_index :droom_people, :user_id

    create_table :droom_groups do |t|
      t.string :name
      t.integer :leader_id
      t.integer :created_by_id
      t.timestamps
    end
    
    create_table :droom_event_sets do |t|
      t.string :name
      t.integer :created_by_id
      t.timestamps
    end

    create_table :droom_membership do |t|
      t.integer :person_id
      t.integer :group_id
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_membership, :person_id
    add_index :droom_membership, :group_id

    create_table :droom_invitations do |t|
      t.integer :person_id
      t.integer :event_id
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_invitations, :event_id
    add_index :droom_invitations, :person_id

    create_table :droom_attachments do |t|
      t.integer :document_id
      t.string :attachee_type
      t.integer :attachee_id
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_attachments, [:attachee_type, :attachee_id]

    create_table :droom_recurrence_rules do |t|
      t.integer :event_id
      t.boolean :active, :default => false
      t.string :period
      t.string :basis
      t.integer :interval, :default => 1
      t.datetime :limiting_date
      t.integer :limiting_count
      t.integer :created_by_id
      t.timestamps
    end
    add_index :droom_recurrence_rules, :event_id

    create_table :droom_venues do |t|
      t.string :name
      t.text :description
      t.string :post_line1
      t.string :post_line2
      t.string :post_city
      t.string :post_region
      t.string :post_country
      t.string :post_code
      t.decimal :lat, :precision => 15, :scale => 10
      t.decimal :lng, :precision => 15, :scale => 10      
      t.timestamps
    end
    add_index  :droom_venues, [:lat, :lng]

end
