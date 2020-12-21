class FlattenedMigrations < ActiveRecord::Migration[5.2]
  def change

    create_table "droom_address_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "relevance"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["relevance"], name: "index_droom_address_types_on_relevance"
    end

    create_table "droom_addresses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "user_id"
      t.integer "address_type_id"
      t.text "address"
      t.string "line_1"
      t.string "line_2"
      t.string "city"
      t.string "region"
      t.string "postal_code"
      t.string "country_code"
      t.boolean "default", default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["default"], name: "index_droom_addresses_on_default"
      t.index ["user_id"], name: "index_droom_addresses_on_user_id"
    end

    create_table "droom_calendars", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.boolean "events_private", default: false
      t.boolean "documents_private", default: false
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["slug"], name: "index_droom_calendars_on_slug"
    end

    create_table "droom_document_attachments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "document_id"
      t.string "attachee_type"
      t.integer "attachee_id"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "category_id"
      t.index ["attachee_type", "attachee_id"], name: "attachee"
    end

    create_table "droom_documents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.integer "version"
      t.string "file_file_name"
      t.string "file_content_type"
      t.integer "file_file_size"
      t.datetime "file_updated_at"
      t.string "file_fingerprint"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "folder_id"
      t.text "extracted_text"
      t.text "extracted_metadata"
      t.datetime "indexed_at"
      t.integer "position", default: 1
      t.boolean "private", default: false
      t.boolean "public", default: false
      t.index ["folder_id"], name: "index_droom_documents_on_folder_id"
      t.index ["private"], name: "index_droom_documents_on_private"
      t.index ["public"], name: "index_droom_documents_on_public"
    end

    create_table "droom_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "user_id"
      t.integer "address_type_id"
      t.string "email"
      t.boolean "default", default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["default"], name: "index_droom_emails_on_default"
      t.index ["email"], name: "index_droom_emails_on_email"
      t.index ["user_id"], name: "index_droom_emails_on_user_id"
    end

    create_table "droom_enquiries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "email"
      t.text "message"
      t.boolean "closed", default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["closed"], name: "index_droom_enquiries_on_closed"
    end

    create_table "droom_event_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.text "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean "private", default: false
      t.boolean "public", default: false
    end

    create_table "droom_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.datetime "start"
      t.datetime "finish"
      t.string "name"
      t.string "slug"
      t.text "description"
      t.string "url"
      t.integer "venue_id"
      t.integer "event_set_id"
      t.integer "created_by_id"
      t.string "uuid"
      t.boolean "all_day"
      t.integer "master_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "calendar_id"
      t.boolean "confidential"
      t.string "timezone"
      t.integer "event_type_id"
      t.datetime "indexed_at"
      t.index ["calendar_id"], name: "index_droom_events_on_calendar_id"
      t.index ["confidential"], name: "index_droom_events_on_confidential"
      t.index ["event_set_id"], name: "index_droom_events_on_event_set_id"
      t.index ["event_type_id"], name: "index_droom_events_on_event_type_id"
      t.index ["master_id"], name: "index_droom_events_on_master_id"
    end

    create_table "droom_folders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "slug"
      t.string "holder_type"
      t.string "holder_id"
      t.integer "parent_id"
      t.boolean "public", default: false
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "private"
      t.string "name"
    end

    create_table "droom_group_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "group_id"
      t.integer "permission_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.integer "leader_id"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "description"
      t.string "mailing_list_name"
      t.boolean "directory"
      t.boolean "privileged", default: false
      t.index ["directory"], name: "index_droom_groups_on_directory"
      t.index ["privileged"], name: "index_droom_groups_on_privileged"
    end

    create_table "droom_helps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "title"
      t.string "slug"
      t.string "category"
      t.integer "main_image_id"
      t.text "content"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["category", "slug"], name: "index_droom_helps_on_category_and_slug"
    end

    create_table "droom_mailing_list_memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "membership_id"
      t.string "address"
      t.string "listname"
      t.string "hide"
      t.string "nomail"
      t.string "ack"
      t.string "not_metoo"
      t.string "digest"
      t.string "plain"
      t.string "one_last_digest"
      t.string "password"
      t.string "lang"
      t.string "name"
      t.integer "user_options"
      t.integer "delivery_status"
      t.string "topics_userinterest"
      t.datetime "delivery_status_timestamp"
      t.string "bi_cookie"
      t.string "bi_score"
      t.string "bi_noticesleft"
      t.date "bi_lastnotice"
      t.date "bi_date"
      t.index ["address", "listname"], name: "index_droom_mailing_list_memberships_on_address_and_listname"
      t.index ["membership_id"], name: "index_droom_mailing_list_memberships_on_membership_id"
    end

    create_table "droom_memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "group_id"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "expires"
      t.integer "user_id"
      t.index ["group_id"], name: "index_droom_memberships_on_group_id"
      t.index ["user_id"], name: "index_droom_memberships_on_user_id"
    end

    create_table "droom_organisation_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "droom_organisations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.string "url"
      t.integer "owner_id"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "organisation_type_id"
      t.string "chinese_name"
      t.string "phone"
      t.text "address"
      t.string "logo_file_name"
      t.string "logo_content_type"
      t.integer "logo_file_size"
      t.datetime "logo_updated_at"
      t.string "facebook_page"
      t.string "twitter_id"
      t.string "instagram_id"
      t.string "weibo_id"
      t.string "image_file_name"
      t.string "image_content_type"
      t.integer "image_file_size"
      t.datetime "image_updated_at"
      t.datetime "approved_at"
      t.integer "approved_by_id"
      t.datetime "disapproved_at"
      t.integer "disapproved_by_id"
      t.boolean "external", default: true
      t.boolean "joinable", default: false
      t.string "email_domain"
      t.index ["email_domain"], name: "index_droom_organisations_on_email_domain"
      t.index ["external"], name: "index_droom_organisations_on_external"
      t.index ["organisation_type_id"], name: "index_droom_organisations_on_organisation_type_id"
      t.index ["owner_id"], name: "index_droom_organisations_on_owner_id"
    end

    create_table "droom_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "service_id"
      t.string "name"
      t.string "slug"
      t.text "description"
      t.integer "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_phones", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "user_id"
      t.integer "address_type_id"
      t.string "phone"
      t.boolean "default", default: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["default"], name: "index_droom_phones_on_default"
      t.index ["phone"], name: "index_droom_phones_on_phone"
      t.index ["user_id"], name: "index_droom_phones_on_user_id"
    end

    create_table "droom_preferences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "created_by_id"
      t.string "key"
      t.string "value"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "uuid"
    end

    create_table "droom_recurrence_rules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "event_id"
      t.boolean "active", default: false
      t.string "period"
      t.string "basis"
      t.integer "interval", default: 1
      t.datetime "limiting_date"
      t.integer "limiting_count"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["event_id"], name: "index_droom_recurrence_rules_on_event_id"
    end

    create_table "droom_scraps", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.text "body"
      t.string "image_file_name"
      t.string "image_content_type"
      t.integer "image_file_size"
      t.datetime "image_updated_at"
      t.integer "image_upload_id"
      t.integer "image_scale_width"
      t.integer "image_scale_height"
      t.integer "image_offset_left"
      t.integer "image_offset_top"
      t.integer "created_by_id"
      t.string "scraptype"
      t.string "note"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "event_id"
      t.integer "document_id"
      t.string "youtube_id"
      t.string "url"
      t.integer "size", default: 1
      t.index ["event_id"], name: "index_droom_scraps_on_event_id"
    end

    create_table "droom_services", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.string "url"
      t.text "description"
    end

    create_table "droom_tag_synonyms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "tag_id"
      t.string "synonym"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tag_id"], name: "index_droom_tag_synonyms_on_tag_id"
    end

    create_table "droom_tag_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "droom_taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "tag_id"
      t.integer "taggee_id"
      t.string "taggee_type"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "droom_tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.integer "parent_id"
      t.integer "created_by_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "tag_type_id"
      t.index ["tag_type_id"], name: "index_droom_tags_on_tag_type_id"
    end

    create_table "droom_user_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.integer "user_id"
      t.integer "group_permission_id"
      t.integer "permission_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "droom_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "title"
      t.string "given_name"
      t.string "family_name"
      t.string "honours"
      t.string "email", default: "", null: false
      t.string "encrypted_password", default: "", null: false
      t.string "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer "sign_in_count", default: 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string "current_sign_in_ip"
      t.string "last_sign_in_ip"
      t.string "authentication_token"
      t.string "password_salt"
      t.boolean "admin", default: false
      t.datetime "reminded_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "phone"
      t.string "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string "unconfirmed_email"
      t.string "uid"
      t.integer "organisation_id"
      t.boolean "organisation_admin", default: false
      t.text "description"
      t.string "post_code"
      t.string "mobile"
      t.datetime "dob"
      t.boolean "female"
      t.string "image_file_name"
      t.string "image_content_type"
      t.integer "image_file_size"
      t.datetime "image_updated_at"
      t.integer "image_offset_top"
      t.integer "image_offset_left"
      t.integer "image_scale_width"
      t.integer "image_scale_height"
      t.string "chinese_name"
      t.string "gender", limit: 1
      t.text "address"
      t.string "country_code"
      t.string "session_id"
      t.string "affiliation"
      t.string "unique_session_id", limit: 20
      t.integer "failed_attempts", default: 0
      t.datetime "locked_at"
      t.string "unlock_token"
      t.datetime "indexed_at"
      t.string "role"
      t.text "merged_with"
      t.boolean "external", default: true
      t.string "mailchimp_email"
      t.integer "mailchimp_rating"
      t.datetime "mailchimp_updated_at"
      t.boolean "gatekeeper", default: false
      t.datetime "last_request_at"
      t.datetime "welcomed_at"
      t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
      t.index ["confirmation_token"], name: "index_droom_users_on_confirmation_token", unique: true
      t.index ["external"], name: "index_droom_users_on_external"
      t.index ["gatekeeper"], name: "index_droom_users_on_gatekeeper"
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    end

    create_table "droom_venues", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.string "post_line1"
      t.string "post_line2"
      t.string "post_city"
      t.string "post_region"
      t.string "post_country"
      t.string "post_code"
      t.string "url"
      t.decimal "lat", precision: 15, scale: 10
      t.decimal "lng", precision: 15, scale: 10
      t.boolean "prepend_article"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "address"
      t.string "slug"
      t.string "country_code"
      t.index ["lat", "lng"], name: "index_droom_venues_on_lat_and_lng"
    end

  end
end
