module Droom::Api
  class ApiController < ::ApplicationController

  private

    def current_resource_owner
      Droom::User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

  end
end
