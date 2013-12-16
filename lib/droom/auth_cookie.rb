require 'signed_json'
require "active_support/core_ext/hash/slice"

module Droom
  class AuthCookie

    def initialize(cookies)
      @cookies = cookies
    end

    # Sets the cookie, referencing the given resource.id (e.g. User)
    def set(resource, options={})
      @cookies[cookie_name] = cookie_options.merge(options).merge(:value => set_auth_values(resource))
    end

    # Unsets the cookie via the HTTP response.
    def unset
      @cookies.delete cookie_name, cookie_options
    end

    # The id of the resource (e.g. User) referenced in the cookie.
    def uid
      value[0]
    end

    def token
      value[1]
    end

    # The Time at which the cookie was created.
    def created_at
      valid? ? Time.at(value[2]) : nil
    end

    # Whether the cookie appears valid.
    def valid?
      present? && values.all?
    end

    def present?
      @cookies[cookie_name].present?
    end

    # Whether the cookie was set since the given Time
    def set_since?(time)
      created_at && created_at >= time
    end

  private
    
    # cookie value format is [uid, auth_token, time]
    #
    def values
      begin
        @values = signer.decode(@cookies[cookie_name])
      rescue SignedJson::Error
        [nil, nil, nil]
      end
    end

    def cookie_name
      Settings.auth.cookie_name
    end

    # Note that this is destructive to all previous authentication tokens even if the cookie is not eventually set.
    def set_auth_values(resource)
      signer.encode [ resource.uid, resource.reset_authentication_token!, Time.now ]
    end

    def cookie_options
      @session_options ||= Rails.configuration.session_options
      @session_options[:domain] = Settings.auth.cookie_domain
      @session_options.slice(:path, :domain, :secure, :httponly)
    end

    def signer
      secret = Settings.auth.secret
      @signer ||= SignedJson::Signer.new(secret)
    end

  end
end