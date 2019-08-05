require 'devise/hooks/cookie_authenticatable'

module Devise
  module Models
    module CookieAuthenticatable
      extend ActiveSupport::Concern
      include Devise::Models::Compatibility

    end
  end
end