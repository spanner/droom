require 'rubygems'
require 'paperclip'
require 'cancan'
require 'kaminari'
require 'icalendar'
require 'haml'
require 'mail_form'

module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom
    config.assets.paths << Droom::Engine.root.join('node_modules')
  end
end
