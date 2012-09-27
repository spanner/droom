# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120921094605) do

  create_table "droom_agenda_sections", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "event_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "droom_document_attachments", :force => true do |t|
    t.integer  "document_id"
    t.string   "attachee_type"
    t.integer  "attachee_id"
    t.integer  "created_by_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "agenda_section_id"
  end

  add_index "droom_document_attachments", ["attachee_type", "attachee_id"], :name => "attachee"

  create_table "droom_documents", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "version"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.integer  "created_by_id"
    t.boolean  "public"
    t.boolean  "private"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "droom_event_sets", :force => true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "droom_events", :force => true do |t|
    t.datetime "start"
    t.datetime "finish"
    t.string   "name"
    t.string   "slug"
    t.text     "description"
    t.string   "url"
    t.integer  "venue_id"
    t.integer  "event_set_id"
    t.integer  "created_by_id"
    t.string   "uuid"
    t.boolean  "all_day"
    t.integer  "master_id"
    t.boolean  "private"
    t.boolean  "public"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "droom_events", ["event_set_id"], :name => "index_droom_events_on_event_set_id"
  add_index "droom_events", ["master_id"], :name => "index_droom_events_on_master_id"
  add_index "droom_events", ["public"], :name => "index_droom_events_on_public"

  create_table "droom_groups", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.integer  "leader_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "droom_invitations", :force => true do |t|
    t.integer  "person_id"
    t.integer  "event_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "droom_invitations", ["event_id"], :name => "index_droom_invitations_on_event_id"
  add_index "droom_invitations", ["person_id"], :name => "index_droom_invitations_on_person_id"

  create_table "droom_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "group_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "droom_memberships", ["group_id"], :name => "index_droom_memberships_on_group_id"
  add_index "droom_memberships", ["person_id"], :name => "index_droom_memberships_on_person_id"

  create_table "droom_people", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.string   "email"
    t.string   "phone"
    t.text     "description"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "user_id"
    t.integer  "created_by_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "post_line1"
    t.string   "post_line2"
    t.string   "post_city"
    t.string   "post_region"
    t.string   "post_country"
    t.string   "post_code"
  end

  add_index "droom_people", ["email"], :name => "index_droom_people_on_email"
  add_index "droom_people", ["user_id"], :name => "index_droom_people_on_user_id"

  create_table "droom_personal_documents", :force => true do |t|
    t.integer  "document_attachment_id"
    t.integer  "person_id"
    t.integer  "version"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "droom_personal_documents", ["document_attachment_id"], :name => "index_droom_personal_documents_on_document_attachment_id"
  add_index "droom_personal_documents", ["person_id"], :name => "index_droom_personal_documents_on_person_id"

  create_table "droom_recurrence_rules", :force => true do |t|
    t.integer  "event_id"
    t.boolean  "active",         :default => false
    t.string   "period"
    t.string   "basis"
    t.integer  "interval",       :default => 1
    t.datetime "limiting_date"
    t.integer  "limiting_count"
    t.integer  "created_by_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "droom_recurrence_rules", ["event_id"], :name => "index_droom_recurrence_rules_on_event_id"

  create_table "droom_venues", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "post_line1"
    t.string   "post_line2"
    t.string   "post_city"
    t.string   "post_region"
    t.string   "post_country"
    t.string   "post_code"
    t.string   "url"
    t.decimal  "lat",             :precision => 15, :scale => 10
    t.decimal  "lng",             :precision => 15, :scale => 10
    t.boolean  "prepend_article"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  add_index "droom_venues", ["lat", "lng"], :name => "index_droom_venues_on_lat_and_lng"

end
