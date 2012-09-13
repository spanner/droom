require 'dav4rack'
require 'dav4rack/file_resource'
require "droom/helpers"
require "droom/engine"
require "droom/user_associations"
require "droom/period"
require "droom/validators"
require "droom/dav_resource"
require 'paperclip/io_adapters/url_adapter'

module Droom
  class DroomError < StandardError; end
end
