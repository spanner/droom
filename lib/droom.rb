require 'dav4rack'
require 'dav4rack/resources/file_resource'
require "droom/monkeys"
require "droom/lazy_hash"
require "droom/model_helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/dav_resource"
require "droom/searchability"
require "droom/taggability"
require "droom/folders"
require "snail"

module Droom
  # Droom configuration is handled by accessors on the Droom base module.
  # Boolean items also offer the interrogative form.
  
  mattr_accessor :root_path,
                 :layout,
                 :email_layout,
                 :email_host,
                 :email_from,
                 :email_return_path,
                 :main_dashboard_modules,
                 :margin_dashboard_modules,
                 :panels,
                 :scrap_types,
                 :dav_root,
                 :dav_subdomain,
                 :use_forenames,
                 :use_separate_mobile_number,
                 :use_titles,
                 :enable_mailing_lists,
                 :mailman_table_name,
                 :mailing_lists_active_by_default,
                 :mailing_lists_digest_by_default,
                 :show_venue_map,
                 :default_document_private,
                 :default_event_private,
                 :dropbox_app_key,
                 :dropbox_app_secret,
                 :user_defaults,
                 :people_sort
  
  class DroomError < StandardError; end
  class PermissionDenied < DroomError; end

  class << self
    def layout
      @@layout ||= "droom/application"
    end

    def email_host
      @@email_host ||= "please-change-email-host-in-droom-initializer.example.com"
    end

    def email_layout
      @@email_layout ||= "droom/email"
    end

    def email_from
      @@email_from ||= "please-change-email_from-in-droom-initializer@example.com"
    end

    def email_return_path
      @@email_return_path ||= email_from
    end

    def people_sort
      @@people_sort ||= "position ASC"
    end

    def sign_out_path
      @@sign_out_path ||= "/users/sign_out"
    end

    def root_path
      @@root_path ||= "dashboard#index"
    end

    def home_country
      Snail.home_country = @@home_country ||= 'gb'
    end

    def main_dashboard_modules
      @@main_dashboard_modules ||= %w{my_future_events my_folders}
    end

    def margin_dashboard_modules
      @@margin_dashboard_modules ||= %w{quicksearch stream}
    end
    
    def panels
      @@panels ||= %w{dropbox email rss devices readers account search admin}
    end
    
    def scrap_types
      @@scrap_types ||= %w{image video text quote link}
    end

    # base path of DAV directory tree, relative to rails root.
    def dav_root
      @@dav_root ||= "webdav"
    end

    # subdomain constraint applied when routing to dav.
    def dav_subdomain
      @@dav_subdomain ||= /dav/
    end

    def use_forenames?
      !!@@use_forenames
    end

    def use_titles?
      !!@@use_titles
    end

    def use_separate_mobile_number?
      !!@@use_separate_mobile_number
    end

    def enable_mailing_lists?
      !!@@enable_mailing_lists
    end

    def mailman_table_name
      @@mailman_table_name ||= 'mailman_mysql'
    end

    def mailing_lists_active_by_default?
      !!@@mailing_lists_active_by_default
    end

    def mailing_lists_digest_by_default?
      !!@@mailing_lists_digest_by_default
    end

    def show_venue_map?
      !!@@show_venue_map
    end

    def suggestible_classes=(hash)
      @@suggestible_classes = hash
    end

    def suggestible_classes
      @@suggestible_classes ||= {
        "event" => "Droom::Event", 
        "person" => "Droom::Person", 
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end

    def searchable_classes
      @@searchable_classes ||= {
        "event" => "Droom::Event",
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end

    def add_suggestible_class(label, klass=nil)
      klass ||= label.titlecase
      suggestible_classes[label] = klass.to_s
    end
    
    # Droom's preferences are arbitrary and open-ended. You can ask for any preference key: if it 
    # doesn't exist you just get back the default value, or nil if there isn't one. This is where you
    # set the defaults.
    #
    def user_defaults
      @@user_defaults ||= Droom::LazyHash.new({
        :email =>  {
          :enabled? => true,
          :mailing_lists? => true,
          :event_invitations? => false,
          :digest? => false
        },
        :dropbox => {
          :strategy => "clicked",
          :events? => true,
        },
        :dav => {
          :enabled? => false,
          :strategy => "clicked",
          :everything? => false,
        }
      })
    end
    
    # Here we are overriding droom default settings in a host app initializer to create local default settings.
    # key should be dot-separated and string-like:
    #
    #   Droom.set_default('email.digest', true)
    #
    # LazyHash#deep_set is a setter that can take compound keys and set nested values. It's defined in lib/lazy_hash.rb.
    #
    def set_user_default(key, value)
      user_defaults.set(key, value)
    end
    
    def user_default(key)
      user_defaults.get(key)
    end
  end
end
