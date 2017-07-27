# encoding: UTF-8

class ConsolidatedMigrations < ActiveRecord::Migration
  def change

    create_table "droom_address_types", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",       limit: 255
      t.string   "relevance",  limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "droom_address_types", ["relevance"], name: "index_droom_address_types_on_relevance", using: :btree

    create_table "droom_addresses", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "user_id",         limit: 4
      t.integer  "address_type_id", limit: 4
      t.text     "address",         limit: 65535
      t.string   "line_1",          limit: 255
      t.string   "line_2",          limit: 255
      t.string   "city",            limit: 255
      t.string   "region",          limit: 255
      t.string   "postal_code",     limit: 255
      t.string   "country_code",    limit: 255
      t.boolean  "default",                       default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "droom_addresses", ["default"], name: "index_droom_addresses_on_default", using: :btree
    add_index "droom_addresses", ["user_id"], name: "index_droom_addresses_on_user_id", using: :btree

    create_table "droom_calendars", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",              limit: 255
      t.string   "slug",              limit: 255
      t.boolean  "events_private",                default: false
      t.boolean  "documents_private",             default: false
      t.integer  "created_by_id",     limit: 4
      t.datetime "created_at",                                    null: false
      t.datetime "updated_at",                                    null: false
    end

    add_index "droom_calendars", ["slug"], name: "index_droom_calendars_on_slug", using: :btree

    create_table "droom_categories", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",          limit: 255
      t.text     "description",   limit: 65535
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
      t.string   "slug",          limit: 255
    end

    create_table "droom_document_attachments", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "document_id",   limit: 4
      t.string   "attachee_type", limit: 255
      t.integer  "attachee_id",   limit: 4
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
      t.integer  "category_id",   limit: 4
    end

    add_index "droom_document_attachments", ["attachee_type", "attachee_id"], name: "attachee", using: :btree

    create_table "droom_documents", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",               limit: 255
      t.text     "description",        limit: 65535
      t.integer  "version",            limit: 4
      t.string   "file_file_name",     limit: 255
      t.string   "file_content_type",  limit: 255
      t.integer  "file_file_size",     limit: 4
      t.datetime "file_updated_at"
      t.string   "file_fingerprint",   limit: 255
      t.integer  "created_by_id",      limit: 4
      t.datetime "created_at",                                       null: false
      t.datetime "updated_at",                                       null: false
      t.integer  "folder_id",          limit: 4
      t.text     "extracted_text",     limit: 65535
      t.text     "extracted_metadata", limit: 65535
      t.datetime "indexed_at"
      t.integer  "position",           limit: 4,     default: 1
      t.boolean  "private",                          default: false
      t.boolean  "public",                           default: false
    end

    add_index "droom_documents", ["folder_id"], name: "index_droom_documents_on_folder_id", using: :btree
    add_index "droom_documents", ["private"], name: "index_droom_documents_on_private", using: :btree
    add_index "droom_documents", ["public"], name: "index_droom_documents_on_public", using: :btree

    create_table "droom_dropbox_documents", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "path",        limit: 255
      t.integer  "document_id", limit: 4
      t.boolean  "modified"
      t.datetime "created_at",              null: false
      t.datetime "updated_at",              null: false
      t.integer  "user_id",     limit: 4
    end

    add_index "droom_dropbox_documents", ["user_id"], name: "index_droom_dropbox_documents_on_user_id", using: :btree

    create_table "droom_dropbox_tokens", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "created_by_id",       limit: 4
      t.string   "access_token",        limit: 255
      t.string   "access_token_secret", limit: 255
      t.datetime "created_at",                      null: false
      t.datetime "updated_at",                      null: false
    end

    create_table "droom_emails", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "user_id",         limit: 4
      t.integer  "address_type_id", limit: 4
      t.string   "email",           limit: 255
      t.boolean  "default",                     default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "droom_emails", ["default"], name: "index_droom_emails_on_default", using: :btree
    add_index "droom_emails", ["email"], name: "index_droom_emails_on_email", using: :btree
    add_index "droom_emails", ["user_id"], name: "index_droom_emails_on_user_id", using: :btree

    create_table "droom_enquiries", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",       limit: 255
      t.string   "email",      limit: 255
      t.text     "message",    limit: 65535
      t.boolean  "closed",                   default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "droom_enquiries", ["closed"], name: "index_droom_enquiries_on_closed", using: :btree

    create_table "droom_event_sets", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",          limit: 255
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    create_table "droom_event_types", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",        limit: 255
      t.string   "slug",        limit: 255
      t.text     "description", limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "private",                   default: false
      t.boolean  "public",                    default: false
    end

    create_table "droom_events", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.datetime "start"
      t.datetime "finish"
      t.string   "name",          limit: 255
      t.string   "slug",          limit: 255
      t.text     "description",   limit: 65535
      t.string   "url",           limit: 255
      t.integer  "venue_id",      limit: 4
      t.integer  "event_set_id",  limit: 4
      t.integer  "created_by_id", limit: 4
      t.string   "uuid",          limit: 255
      t.boolean  "all_day"
      t.integer  "master_id",     limit: 4
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
      t.integer  "calendar_id",   limit: 4
      t.boolean  "confidential"
      t.string   "timezone",      limit: 255
      t.integer  "event_type_id", limit: 4
      t.datetime "indexed_at"
    end

    add_index "droom_events", ["calendar_id"], name: "index_droom_events_on_calendar_id", using: :btree
    add_index "droom_events", ["confidential"], name: "index_droom_events_on_confidential", using: :btree
    add_index "droom_events", ["event_set_id"], name: "index_droom_events_on_event_set_id", using: :btree
    add_index "droom_events", ["event_type_id"], name: "index_droom_events_on_event_type_id", using: :btree
    add_index "droom_events", ["master_id"], name: "index_droom_events_on_master_id", using: :btree

    create_table "droom_folders", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "slug",          limit: 255
      t.string   "holder_type",   limit: 255
      t.string   "holder_id",     limit: 255
      t.integer  "parent_id",     limit: 4
      t.boolean  "public",                    default: false
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                                null: false
      t.datetime "updated_at",                                null: false
      t.boolean  "private"
      t.string   "name",          limit: 255
    end

    create_table "droom_group_invitations", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer "group_id",      limit: 4
      t.integer "event_id",      limit: 4
      t.integer "created_by_id", limit: 4
    end

    create_table "droom_group_permissions", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "group_id",      limit: 4
      t.integer  "permission_id", limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_groups", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",              limit: 255
      t.string   "slug",              limit: 255
      t.integer  "leader_id",         limit: 4
      t.integer  "created_by_id",     limit: 4
      t.datetime "created_at",                                      null: false
      t.datetime "updated_at",                                      null: false
      t.text     "description",       limit: 65535
      t.string   "mailing_list_name", limit: 255
      t.boolean  "directory"
      t.boolean  "privileged",                      default: false
    end

    add_index "droom_groups", ["directory"], name: "index_droom_groups_on_directory", using: :btree
    add_index "droom_groups", ["privileged"], name: "index_droom_groups_on_privileged", using: :btree

    create_table "droom_invitations", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "event_id",            limit: 4
      t.integer  "created_by_id",       limit: 4
      t.datetime "created_at",                    null: false
      t.datetime "updated_at",                    null: false
      t.integer  "group_invitation_id", limit: 4
      t.integer  "user_id",             limit: 4
    end

    add_index "droom_invitations", ["event_id"], name: "index_droom_invitations_on_event_id", using: :btree
    add_index "droom_invitations", ["user_id"], name: "index_droom_invitations_on_user_id", using: :btree

    create_table "droom_mailing_list_memberships", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "membership_id",             limit: 4
      t.string   "address",                   limit: 255
      t.string   "listname",                  limit: 255
      t.string   "hide",                      limit: 255
      t.string   "nomail",                    limit: 255
      t.string   "ack",                       limit: 255
      t.string   "not_metoo",                 limit: 255
      t.string   "digest",                    limit: 255
      t.string   "plain",                     limit: 255
      t.string   "one_last_digest",           limit: 255
      t.string   "password",                  limit: 255
      t.string   "lang",                      limit: 255
      t.string   "name",                      limit: 255
      t.integer  "user_options",              limit: 4
      t.integer  "delivery_status",           limit: 4
      t.string   "topics_userinterest",       limit: 255
      t.datetime "delivery_status_timestamp"
      t.string   "bi_cookie",                 limit: 255
      t.string   "bi_score",                  limit: 255
      t.string   "bi_noticesleft",            limit: 255
      t.date     "bi_lastnotice"
      t.date     "bi_date"
    end

    add_index "droom_mailing_list_memberships", ["address", "listname"], name: "index_droom_mailing_list_memberships_on_address_and_listname", using: :btree
    add_index "droom_mailing_list_memberships", ["membership_id"], name: "index_droom_mailing_list_memberships_on_membership_id", using: :btree

    create_table "droom_memberships", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "group_id",      limit: 4
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",              null: false
      t.datetime "updated_at",              null: false
      t.datetime "expires"
      t.integer  "user_id",       limit: 4
    end

    add_index "droom_memberships", ["group_id"], name: "index_droom_memberships_on_group_id", using: :btree
    add_index "droom_memberships", ["user_id"], name: "index_droom_memberships_on_user_id", using: :btree

    create_table "droom_organisations", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",          limit: 255
      t.text     "description",   limit: 65535
      t.string   "url",           limit: 255
      t.integer  "owner_id",      limit: 4
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
    end

    add_index "droom_organisations", ["owner_id"], name: "index_droom_organisations_on_owner_id", using: :btree

    create_table "droom_pages", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "title",         limit: 255
      t.string   "slug",          limit: 255
      t.text     "summary",       limit: 65535
      t.text     "body",          limit: 65535
      t.text     "rendered_body", limit: 65535
      t.string   "video_id",      limit: 255
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
    end

    create_table "droom_permissions", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "service_id",  limit: 4
      t.string   "name",        limit: 255
      t.string   "slug",        limit: 255
      t.text     "description", limit: 65535
      t.integer  "position",    limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_personal_folders", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "folder_id",  limit: 4
      t.datetime "created_at",           null: false
      t.datetime "updated_at",           null: false
      t.integer  "user_id",    limit: 4
    end

    add_index "droom_personal_folders", ["user_id"], name: "index_droom_personal_folders_on_user_id", using: :btree

    create_table "droom_phones", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "user_id",         limit: 4
      t.integer  "address_type_id", limit: 4
      t.string   "phone",           limit: 255
      t.boolean  "default",                     default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "droom_phones", ["default"], name: "index_droom_phones_on_default", using: :btree
    add_index "droom_phones", ["phone"], name: "index_droom_phones_on_phone", using: :btree
    add_index "droom_phones", ["user_id"], name: "index_droom_phones_on_user_id", using: :btree

    create_table "droom_preferences", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "created_by_id", limit: 4
      t.string   "key",           limit: 255
      t.string   "value",         limit: 255
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
      t.string   "uuid",          limit: 255
      t.integer  "person_id",     limit: 4
    end

    create_table "droom_scraps", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",               limit: 255
      t.text     "body",               limit: 65535
      t.string   "image_file_name",    limit: 255
      t.string   "image_content_type", limit: 255
      t.integer  "image_file_size",    limit: 4
      t.datetime "image_updated_at"
      t.integer  "image_upload_id",    limit: 4
      t.integer  "image_scale_width",  limit: 4
      t.integer  "image_scale_height", limit: 4
      t.integer  "image_offset_left",  limit: 4
      t.integer  "image_offset_top",   limit: 4
      t.integer  "created_by_id",      limit: 4
      t.string   "scraptype",          limit: 255
      t.text     "note",               limit: 65535
      t.datetime "created_at",                                   null: false
      t.datetime "updated_at",                                   null: false
      t.integer  "event_id",           limit: 4
      t.integer  "document_id",        limit: 4
      t.string   "youtube_id",         limit: 255
      t.string   "url",                limit: 255
      t.integer  "size",               limit: 4,     default: 1
    end

    create_table "droom_services", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string "name",        limit: 255
      t.string "slug",        limit: 255
      t.string "url",         limit: 255
      t.text   "description", limit: 65535
    end

    create_table "droom_taggings", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "tag_id",        limit: 4
      t.integer  "taggee_id",     limit: 4
      t.string   "taggee_type",   limit: 255
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    create_table "droom_tags", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",          limit: 255
      t.integer  "parent_id",     limit: 4
      t.integer  "created_by_id", limit: 4
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    create_table "droom_user_permissions", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.integer  "user_id",             limit: 4
      t.integer  "group_permission_id", limit: 4
      t.integer  "permission_id",       limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_users", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "family_name",            limit: 255
      t.string   "given_name",             limit: 255
      t.boolean  "admin",                                default: false
      t.datetime "reminded_at"
      t.string   "email",                  limit: 255,   default: "",    null: false
      t.string   "encrypted_password",     limit: 255,   default: "",    null: false
      t.string   "reset_password_token",   limit: 255
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",          limit: 4,     default: 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip",     limit: 255
      t.string   "last_sign_in_ip",        limit: 255
      t.string   "authentication_token",   limit: 255
      t.string   "password_salt",          limit: 255
      t.datetime "created_at",                                           null: false
      t.datetime "updated_at",                                           null: false
      t.string   "confirmation_token",     limit: 255
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string   "unconfirmed_email",      limit: 255
      t.string   "title",                  limit: 255
      t.string   "uid",                    limit: 255
      t.integer  "organisation_id",        limit: 4
      t.string   "phone",                  limit: 255
      t.text     "description",            limit: 65535
      t.string   "post_code",              limit: 255
      t.string   "mobile",                 limit: 255
      t.datetime "dob"
      t.boolean  "female"
      t.string   "image_file_name",        limit: 255
      t.string   "image_content_type",     limit: 255
      t.integer  "image_file_size",        limit: 4
      t.datetime "image_updated_at"
      t.integer  "image_offset_top",       limit: 4
      t.integer  "image_offset_left",      limit: 4
      t.integer  "image_scale_width",      limit: 4
      t.integer  "image_scale_height",     limit: 4
      t.string   "chinese_name",           limit: 255
      t.string   "gender",                 limit: 1
      t.string   "honours",                limit: 255
      t.text     "address",                limit: 65535
      t.string   "country_code",           limit: 255
      t.string   "session_id",             limit: 255
      t.boolean  "email_news",                           default: false
      t.boolean  "news_projects",                        default: false
      t.boolean  "news_events",                          default: false
      t.boolean  "news_stream",                          default: false
      t.string   "affiliation",            limit: 255
      t.string   "unique_session_id",      limit: 20
      t.integer  "failed_attempts",        limit: 4,     default: 0
      t.datetime "locked_at"
      t.string   "unlock_token",           limit: 255
      t.datetime "indexed_at"
    end

    add_index "droom_users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
    add_index "droom_users", ["confirmation_token"], name: "index_droom_users_on_confirmation_token", unique: true, using: :btree
    add_index "droom_users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

    create_table "droom_venues", options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8', force: :cascade do |t|
      t.string   "name",            limit: 255
      t.text     "description",     limit: 65535
      t.string   "post_line1",      limit: 255
      t.string   "post_line2",      limit: 255
      t.string   "post_city",       limit: 255
      t.string   "post_region",     limit: 255
      t.string   "post_country",    limit: 255
      t.string   "post_code",       limit: 255
      t.string   "url",             limit: 255
      t.decimal  "lat",                           precision: 15, scale: 10
      t.decimal  "lng",                           precision: 15, scale: 10
      t.boolean  "prepend_article"
      t.datetime "created_at",                                              null: false
      t.datetime "updated_at",                                              null: false
      t.text     "address",         limit: 65535
      t.string   "slug",            limit: 255
      t.string   "country_code",    limit: 255
    end

    add_index "droom_venues", ["lat", "lng"], name: "index_droom_venues_on_lat_and_lng", using: :btree

  end
end
