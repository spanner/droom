require 'rubygems'
require 'active_model_serializers'
require 'acts_as_list'
require 'acts_as_tree'
require 'cancan'
require 'chronic'
require 'date_validator'
require 'devise'
require 'devise-security'
require 'devise_zxcvbn'
require 'digest'
require 'friendly_mime'
require 'geocoder'
require 'gibbon'
require 'haml'
require 'icalendar'
require 'kaminari'
require 'mail_form'
require 'mustache'
require 'open-uri'
require 'paperclip'
require 'searchkick'
require 'tod'
require 'uuidtools'
require 'video_info'


module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom

    class << self
      def cable
        @cable ||= ActionCable::Server::Base.new(config: Droom.cable_config)
      end
    end

    initializer "droom.integration" do
      Devise.parent_controller = "Droom::DroomController"
    end

    config.assets.paths << Droom::Engine.root.join('node_modules')

    ActiveSupport::Reloader.to_prepare do
      Devise::SessionsController.layout Droom.devise_layout
      Devise::RegistrationsController.layout Droom.devise_layout
      Devise::ConfirmationsController.layout Droom.devise_layout
      Devise::UnlocksController.layout Droom.devise_layout
      Devise::PasswordsController.layout Droom.devise_layout
    end

  end

  class << self
    def cable_config
      unless @cable_config
        @cable_config = ActionCable::Server::Configuration.new
        @cable_config.connection_class = -> { Droom::Connection }
        @cable_config.logger = ::Rails.logger
      end
      @cable_config
    end
  end
end
