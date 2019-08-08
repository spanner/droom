require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class CookieAuthenticatable < Authenticatable

      def valid?
        cookie.valid?
      end

      def fresh?
        cookie.fresh?
      end

      def authenticate!
        Rails.logger.warn "⚠️ CookieAuthenticatable.authenticate! #{valid?} && #{fresh?} && #{resource} && #{validate(resource)}"
        if valid? && fresh? && resource && validate(resource)
          success!(resource)
        else
          cookie.unset
          pass
        end
      end

      def store?
        false
      end

      private

      def cookie
        @cookie ||= Droom::AuthCookie.new(cookies)
      end

      def resource
        # returns nil when user is missing.
        @resource ||= mapping.to.where(unique_session_id: cookie.token).first
      end
    end
  end
end

Warden::Strategies.add(:cookie_authenticatable, Devise::Strategies::CookieAuthenticatable)

