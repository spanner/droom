require 'rubygems'
require 'paperclip'
require 'devise'
require 'devise-security'
require 'devise_zxcvbn'
require 'cancan'
require 'kaminari'
require 'icalendar'
require 'haml'
require 'mail_form'
require 'searchkick'
require 'active_model_serializers'
require 'acts_as_list'
require 'tod'
require 'open-uri'
require 'uuidtools'
require 'date_validator'
require 'acts_as_tree'
require 'mustache'
require 'digest'
require 'gibbon'
require 'geocoder'
require 'video_info'
require 'friendly_mime'



module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom

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
end
