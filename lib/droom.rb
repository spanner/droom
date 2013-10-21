require "droom/monkeys"
require "droom/cropper"
require "droom/lazy_hash"
require "droom/model_helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/searchability"
require "droom/taggability"
require "droom/folders"
require "snail"
require "youtube_it"

module Droom  
  # Droom configuration is handled by accessors on the Droom base module.
  # Boolean items also offer the interrogative form.
  
  mattr_accessor :root_path,
                 :home_url,
                 :suggestible_classes,
                 :searchable_classes,
                 :yt_client,
                 :layout,
                 :devise_layout,
                 :email_layout,
                 :email_host,
                 :email_from,
                 :email_from_name,
                 :email_return_path,
                 :main_dashboard_modules,
                 :margin_dashboard_modules,
                 :panels,
                 :scrap_types,
                 :default_scrap_type,
                 :use_chinese_names,
                 :use_biogs,
                 :use_separate_mobile_number,
                 :use_titles,
                 :use_organisations,
                 :enable_mailing_lists,
                 :mailman_table_name,
                 :mailing_lists_active_by_default,
                 :mailing_lists_digest_by_default,
                 :show_venue_map,
                 :dropbox_app_key,
                 :dropbox_app_secret,
                 :dropbox_app_name,
                 :user_defaults,
                 :people_sort,
                 :required_calendar_names,
                 :stream_shared,
                 :aws_bucket_name,
                 :all_events_public,
                 :all_documents_public,
                 :password_pattern,
                 :separate_calendars
  
  class DroomError < StandardError; end
  class PermissionDenied < DroomError; end

  class << self
    def home_url
      @@home_url ||= "http://example.com"
    end
    
    def layout
      @@layout ||= "application"
    end

    def devise_layout
      @@devise_layout ||= "application"
    end

    def email_host
      @@email_host ||= "please-change-email-host-in-droom-initializer.example.com"
    end

    def email_layout
      @@email_layout ||= "email"
    end

    def email_from
      @@email_from ||= "please-change-email_from-in-droom-initializer@example.com"
    end

    def email_from_name
      @@email_from ||= "Please Set Email-From Name In Droom Initializer"
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
      @@panels ||= %w{configuration search admin}
    end
    
    def scrap_types
      @@scrap_types ||= %w{image video text quote link event document}
    end
    
    def default_scrap_type
      @@default_scrap_type ||= 'text'
    end

    def use_chinese_names?
      !!@@use_chinese_names
    end

    def use_titles?
      !!@@use_titles
    end
    
    def use_biogs?
      !!@@use_biogs
    end
    
    def use_organisations?
      !!@@use_organisations
    end

    def stream_shared?
      !!@@stream_shared
    end

    def use_separate_mobile_number?
      !!@@use_separate_mobile_number
    end

    def enable_mailing_lists?
      !!@@enable_mailing_lists
    end

    def calendar_closed?
      !!@@calendar_closed
    end
    
    def all_events_public?
      !!@@all_events_public
    end
    
    def all_documents_public?
      !!@@all_documents_public
    end

    def dropbox_app_name
      @@dropbox_app_name ||= 'droom'
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

    def suggestible_classes
      @@suggestible_classes ||= {
        "event" => "Droom::Event", 
        "user" => "Droom::User", 
        "document" => "Droom::Document",
        "group" => "Droom::Group",
        "venue" => "Droom::Venue"
      }
    end

    def add_suggestible_class(label, klass=nil)
      klass ||= label.camelize
      suggestible_classes[label] = klass.to_s
    end

    def yt_client
      @@yt_client ||= YouTubeIt::Client.new(:dev_key => "AI39si473p0K4e6id0ZrM1vniyk8pdbqr67hH39hyFjW_JQoLg9xi6BecWFtraoPMCeYQmRgIc_XudGKVU8tmeQF8VHwjOUg8Q")
    end

    def aws_bucket_name
      @@aws_bucket_name ||= nil
    end

    def aws_bucket
      @@aws_bucket ||= Fog::Storage.new(Droom::Engine.config.paperclip_defaults[:fog_credentials]).directories.get(@@aws_bucket_name)
    end

    def required_calendar_names
      @@required_calendar_names ||= %w{main stream}
    end
    
    def separate_calendars?
      !!@@separate_calendars
    end
    
    def password_pattern
      @@password_pattern ||= "{,6}"
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
