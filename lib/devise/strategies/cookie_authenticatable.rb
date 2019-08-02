require 'devise'

module Devise
  module Strategies
    class CookieAuthenticatable < ::Devise::Strategies::Authenticatable

      def valid?
        cookie.valid?
      end

      def fresh?
        cookie.fresh?
      end

      def authenticate!
        if valid? && fresh? && resource && validate(resource)
          Rails.logger.warn "[cookie_authenticatable] ⚠️ cookie authenticated! #{resource}"
          success!(resource)
        else
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