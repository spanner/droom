require 'dav4rack'
require 'dav4rack/file_resource'
require "droom/monkeys"
require "droom/helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/dav_resource"
require "snail"

module Droom
  mattr_accessor :user_class, :layout, :sign_in_path, :sign_out_path, :user_class, :root_path, :active_dashboard_modules, :dav_root, :dav_subdomain, :use_forenames, :show_venue_map
  
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

  end
end
