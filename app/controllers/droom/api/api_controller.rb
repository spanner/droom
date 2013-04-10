module Droom::Api
  class ApiController < ::ApplicationController

  private

    def current_resource_owner
      Rails.logger.warn "!!! in current_resource_owner, doorkeeper_token is: #{doorkeeper_token.inspect}"
      
      Droom::User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

  end
end
