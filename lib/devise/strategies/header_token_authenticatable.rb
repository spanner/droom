require 'devise'

module Devise
  module Strategies
    class HeaderTokenAuthenticatable < ::Devise::Strategies::Authenticatable

      def valid?
        Rails.logger.warn "~~~> HeaderTokenAuthenticatable token_and_options #{token_and_options.inspect}"
        
        token_and_options.present?
      end

      def authenticate!
        if resource && validate(resource)
          success!(resource)
        else
          pass
        end
      end
      
      def token_and_options
        @values ||= ActionController::HttpAuthentication::Token.token_and_options(request)
      end
      
      def store?
        false
      end

    private

      def resource
        # returns nil when user is missing.
        @resource ||= mapping.to.where(:authentication_token => token_and_options[0]).first
      end

    end
  end

  module Models
    module HeaderTokenAuthenticatable
      # I'm sure this is configurable away, but who can find that sort of thing in devise?
    end
  end
end