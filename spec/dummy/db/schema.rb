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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130724124778) do

  create_table "droom_agenda_categories", force: true do |t|
    t.integer  "event_id"
    t.integer  "category_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "droom_calendars", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.boolean  "events_private",    default: false
    t.boolean  "documents_private", default: false
    t.integer  "created_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "droom_calendars", ["slug"], name: "index_droom_calendars_on_slug", using: :btree

  create_table "droom_categories", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "slug"
  end

  create_table "droom_document_attachments", force: true do |t|
    t.integer  "document_id"
    t.string   "attachee_type"
    t.integer  "attachee_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "category_id"
  end

  add_index "droom_document_attachments", ["attachee_type", "attachee_id"], name: "attachee", using: :btree

  create_table "droom_document_links", force: true do |t|
    t.integer  "person_id"
    t.integer  "document_attachment_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "droom_document_links", ["document_attachment_id"], name: "index_droom_document_links_on_document_attachment_id", using: :btree
  add_index "droom_document_links", ["person_id"], name: "index_droom_document_links_on_person_id", using: :btree

  create_table "droom_documents", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "version"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.integer  "created_by_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "folder_id"
    t.text     "extracted_text"
    t.text     "extracted_metadata"
  end

  add_index "droom_documents", ["folder_id"], name: "index_droom_documents_on_folder_id", using: :btree

  create_table "droom_dropbox_documents", force: true do |t|
    t.string   "path"
    t.integer  "document_id"
    t.boolean  "modified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "droom_dropbox_documents", ["user_id"], name: "index_droom_dropbox_documents_on_user_id", using: :btree

  create_table "droom_dropbox_tokens", force: true do |t|
    t.integer  "created_by_id"
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token_secret"
  end

  create_table "droom_event_sets", force: true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "droom_events", force: true do |t|
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
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "calendar_id"
    t.boolean  "confidential"
  end

  add_index "droom_events", ["calendar_id"], name: "index_droom_events_on_calendar_id", using: :btree
  add_index "droom_events", ["confidential"], name: "index_droom_events_on_confidential", using: :btree
  add_index "droom_events", ["event_set_id"], name: "index_droom_events_on_event_set_id", using: :btree
  add_index "droom_events", ["master_id"], name: "index_droom_events_on_master_id", using: :btree

  create_table "droom_folders", force: true do |t|
    t.string   "slug"
    t.string   "holder_type"
    t.string   "holder_id"
    t.integer  "parent_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.boolean  "private"
    t.string   "name"
  end

  add_index "droom_folders", ["parent_id"], name: "index_droom_folders_on_parent_id", using: :btree

  create_table "droom_group_invitations", force: true do |t|
    t.integer "group_id"
    t.integer "event_id"
    t.integer "created_by_id"
  end

  create_table "droom_group_permissions", force: true do |t|
    t.integer  "group_id"
    t.integer  "permission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "droom_groups", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.integer  "leader_id"
    t.integer  "created_by_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.text     "description"
    t.string   "mailing_list_name"
    t.boolean  "directory"
  end

  add_index "droom_groups", ["directory"], name: "index_droom_groups_on_directory", using: :btree

  create_table "droom_invitations", force: true do |t|
    t.integer  "event_id"
    t.integer  "created_by_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "group_invitation_id"
    t.integer  "response",            default: 1
    t.integer  "user_id"
  end

  add_index "droom_invitations", ["event_id"], name: "index_droom_invitations_on_event_id", using: :btree
  add_index "droom_invitations", ["user_id"], name: "index_droom_invitations_on_user_id", using: :btree

  create_table "droom_mailing_list_memberships", force: true do |t|
    t.integer  "membership_id"
    t.string   "address"
    t.string   "listname"
    t.string   "hide"
    t.string   "nomail"
    t.string   "ack"
    t.string   "not_metoo"
    t.string   "digest"
    t.string   "plain"
    t.string   "one_last_digest"
    t.string   "password"
    t.string   "lang"
    t.string   "name"
    t.integer  "user_options"
    t.integer  "delivery_status"
    t.string   "topics_userinterest"
    t.datetime "delivery_status_timestamp"
    t.string   "bi_cookie"
    t.string   "bi_score"
    t.string   "bi_noticesleft"
    t.date     "bi_lastnotice"
    t.date     "bi_date"
  end

  add_index "droom_mailing_list_memberships", ["address", "listname"], name: "index_droom_mailing_list_memberships_on_address_and_listname", using: :btree
  add_index "droom_mailing_list_memberships", ["membership_id"], name: "index_droom_mailing_list_memberships_on_membership_id", using: :btree

  create_table "droom_memberships", force: true do |t|
    t.integer  "group_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "expires"
    t.integer  "user_id"
  end

  add_index "droom_memberships", ["group_id"], name: "index_droom_memberships_on_group_id", using: :btree
  add_index "droom_memberships", ["user_id"], name: "index_droom_memberships_on_user_id", using: :btree

  create_table "droom_pages", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "summary"
    t.text     "body"
    t.text     "rendered_body"
    t.string   "video_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "droom_permissions", force: true do |t|
    t.integer  "service_id"
    t.string   "name"
    t.string   "slug"
    t.text     "description"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "droom_personal_folders", force: true do |t|
    t.integer  "folder_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
  end

  add_index "droom_personal_folders", ["user_id"], name: "index_droom_personal_folders_on_user_id", using: :btree

  create_table "droom_preferences", force: true do |t|
    t.integer  "created_by_id"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
  end

  create_table "droom_recurrence_rules", force: true do |t|
    t.integer  "event_id"
    t.boolean  "active",         default: false
    t.string   "period"
    t.string   "basis"
    t.integer  "interval",       default: 1
    t.datetime "limiting_date"
    t.integer  "limiting_count"
    t.integer  "created_by_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "droom_recurrence_rules", ["event_id"], name: "index_droom_recurrence_rules_on_event_id", using: :btree

  create_table "droom_scraps", force: true do |t|
    t.string   "name"
    t.text     "body"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "created_by_id"
    t.string   "scraptype"
    t.string   "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_id"
    t.integer  "document_id"
  end

  add_index "droom_scraps", ["event_id"], name: "index_droom_scraps_on_event_id", using: :btree

  create_table "droom_services", force: true do |t|
    t.string "name"
    t.string "slug"
    t.string "url"
    t.text   "description"
  end

  create_table "droom_taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggee_id"
    t.string   "taggee_type"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "droom_tags", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "created_by_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "droom_user_permissions", force: true do |t|
    t.integer  "user_id"
    t.integer  "group_permission_id"
    t.integer  "permission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "droom_users", force: true do |t|
    t.string   "name"
    t.string   "forename"
    t.boolean  "admin",                  default: false
    t.datetime "reminded_at"
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "title"
    t.string   "uid"
    t.integer  "organisation_id"
    t.string   "phone"
    t.text     "description"
    t.string   "post_line1"
    t.string   "post_line2"
    t.string   "post_city"
    t.string   "post_region"
    t.string   "post_country"
    t.string   "post_code"
    t.string   "mobile"
    t.datetime "dob"
    t.boolean  "female"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "image_offset_top"
    t.integer  "image_offset_left"
    t.integer  "image_scale_width"
    t.integer  "image_scale_height"
  end

  add_index "droom_users", ["confirmation_token"], name: "index_droom_users_on_confirmation_token", unique: true, using: :btree
  add_index "droom_users", ["email"], name: "index_droom_users_on_email", unique: true, using: :btree
  add_index "droom_users", ["reset_password_token"], name: "index_droom_users_on_reset_password_token", unique: true, using: :btree

  create_table "droom_venues", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "post_line1"
    t.string   "post_line2"
    t.string   "post_city"
    t.string   "post_region"
    t.string   "post_country"
    t.string   "post_code"
    t.string   "url"
    t.decimal  "lat",             precision: 15, scale: 10
    t.decimal  "lng",             precision: 15, scale: 10
    t.boolean  "prepend_article"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "droom_venues", ["lat", "lng"], name: "index_droom_venues_on_lat_and_lng", using: :btree

end
