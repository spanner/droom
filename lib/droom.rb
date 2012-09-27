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
  class DroomError < StandardError; end
  
  class << self
    def user_class=(klass)
      @@user_class = klass.to_s
    end
  
    def user_class
      (@@user_class || "User").constantize
    end
  end
end
