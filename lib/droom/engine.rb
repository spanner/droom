require 'rubygems'
require 'msg'
require 'paperclip'
require 'fog'
require 'devise'
require 'devise-encryptable'
require 'cancan'
require 'kaminari'
require 'icalendar'
require 'haml'

module Droom
  class Engine < ::Rails::Engine
    isolate_namespace Droom

    initializer "droom.integration" do
      Devise.parent_controller = "Droom::EngineController"
      ActiveRecord::Base.send :include, Droom::Taggability
      ActiveRecord::Base.send :include, Droom::Folders
      ActiveSupport.on_load :action_controller do
        helper Droom::DroomHelper
      end
    end
    
    config.to_prepare do
      Devise::SessionsController.layout Droom.devise_layout
      Devise::RegistrationsController.layout Droom.devise_layout
      Devise::ConfirmationsController.layout Droom.devise_layout
      Devise::UnlocksController.layout Droom.devise_layout
      Devise::PasswordsController.layout Droom.devise_layout
      
      Warden::Strategies.add(:cookie_authenticatable, Devise::Strategies::CookieAuthenticatable)

      Warden::Manager.after_set_user do |user, warden, options|
        warden.env["devise.skip_storage"] = true
        Droom::AuthCookie.new(warden.cookies).set(user)
      end

      Warden::Manager.before_logout do |user, warden, options|
        Droom::AuthCookie.new(warden.cookies).unset
      end
    end
    
  end
end
