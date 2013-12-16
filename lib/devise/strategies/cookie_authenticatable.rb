require 'devise'

module Devise::Strategies
  class CookieAuthenticatable < ::Devise::Strategies::Authenticatable

    def valid?
      Rails.logger.warn "~~~> CookieAuthenticatable cookie is #{cookie.inspect}"
      cookie.valid?
    end

    def authenticate!
      if fresh?(cookie) && resource && validate(resource)
        success!(resource)
      else
        pass
      end
    end

    private

    def cookie
      @cookie ||= Droom::AuthCookie.new(cookies)
    end

    def fresh?(cookie)
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

Warden::Strategies.add(:cookie_authenticatable, Devise::Strategies::CookieAuthenticatable)
