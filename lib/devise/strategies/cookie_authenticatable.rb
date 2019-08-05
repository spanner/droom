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
        Rails.logger.warn "[cookie_authenticatable] ⚠️ cookie authenticate? #{cookie.inspect}"
        if valid? && fresh? && resource && validate(resource)
          Rails.logger.warn "[cookie_authenticatable] ⚠️ cookie authenticated! #{resource.inspect}"
          success!(resource)
        else
          cookie.unset
          pass
        end
      end

      private

      def cookie
        @cookie ||= Droom::AuthCookie.new(cookies)
      end

      def resource
        # returns nil when user is missing.
        Rails.logger.warn "[cookie_authenticatable] ⚠️ cookie token found: #{cookie.token}"
        @resource ||= mapping.to.where(unique_session_id: cookie.token).first
        Rails.logger.warn "[cookie_authenticatable] ⚠️ cookie resource found: #{@resource}"
        @resource
      end
    end
  end
end

Warden::Strategies.add(:cookie_authenticatable, Devise::Strategies::CookieAuthenticatable)

