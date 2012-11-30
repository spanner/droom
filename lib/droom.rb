require 'dav4rack'
require 'dav4rack/file_resource'
require "droom/monkeys"
require "droom/helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/dav_resource"
require "droom/searchability"
require "droom/taggability"
require "snail"

module Droom
  mattr_accessor :user_class, :layout, :sign_in_path, :sign_out_path, :user_class, :root_path, :active_dashboard_modules, :dav_root, :dav_subdomain, :use_forenames, :show_venue_map, :people_sort
  
  class DroomError < StandardError; end
  class PermissionDenied < DroomError; end
  
  class << self
    def user_class=(klass)
      @@user_class = klass.to_s
    end
  
    def user_class
      (@@user_class ||= "User").constantize
    end

    def layout
      @@layout ||= "application"
    end

    def sign_in_path
      @@sign_in_path ||= "/users/sign_in"
    end

    def sign_out_path
      @@sign_out_path ||= "/users/sign_out"
    end

    def root_path
      @@root_path ||= "dashboard#index"
    end

    def people_sort
      @@people_sort ||= "position ASC"
    end
    
    def home_country
      Snail.home_country = @@home_country ||= 'gb'
    end

    def active_dashboard_modules
      @@active_dashboard_modules ||= %w{my_future_events my_past_events my_group_documents}
    end
    
    # base path of DAV directory tree, relative to rails root.
    def dav_root
      @@dav_root ||= "webdav"
    end
    
    # subdomain constraint applied when routing to dav.
    def dav_subdomain
      @@dav_subdomain ||= /dav/
    end

    def use_forenamnes
      !!@@use_forenames
    end

    def show_venue_map
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

    def add_suggestible_class(label, klass=nil)
      klass ||= label.titlecase
      suggestible_classes[label] = klass.to_s
    end
  end
end
