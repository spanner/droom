module Droom
  class IndexUserJob < ActiveJob::Base
    #queue_as :default

    def perform
      Droom::User.reindex
    end
  end
end
