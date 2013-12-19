require 'devise'

module Devise
  module Strategies
    class CookieAuthenticatable < ::Devise::Strategies::Authenticatable

      def valid?
        cookie.valid?
      end

      def authenticate!
        if fresh? && resource && validate(resource)
          success!(resource)
        else
          pass
        end
      end

      private

      def cookie
        @cookie ||= Droom::AuthCookie.new(cookies)
      end

      def fresh?
        cookie.set_since?(Time.now - Settings.auth.cookie_period.hours)
      end

      def resource
        # returns nil when user is missing.
        @resource ||= mapping.to.where(:uid => cookie.uid, :authentication_token => cookie.token).first
      end

      def pass
        cookie.unset
        super
      end
    end
  end

  module Models
    module CookieAuthenticatable
      # I'm sure this is configurable away, but who can find that sort of thing in devise?
    end
  end
end