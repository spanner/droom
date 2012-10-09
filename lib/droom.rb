require 'dav4rack'
require 'dav4rack/file_resource'
require "droom/monkeys"
require "droom/helpers"
require "droom/renderers"
require "droom/engine"
require "droom/validators"
require "droom/dav_resource"
require 'paperclip/io_adapters/url_adapter'

module Droom
  mattr_accessor :user_class, :layout, :sign_in_path, :sign_out_path, :user_class, :root_path, :active_dashboard_modules, :dav_root, :use_forenames
  
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
    
    def active_dashboard_modules
      @@active_dashboard_modules ||= %w{my_future_events my_past_events my_group_documents}
    end
    
    def dav_root
      @@dav_root ||= "webdav"
    end
    
    def use_forenamnes
      !!@@use_forenames
    end

  end
end
