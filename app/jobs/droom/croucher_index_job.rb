module Droom
  class CroucherIndexJob < ActiveJob::Base
    #queue_as :default

    def perform
      Droom::User.reindex
    end
  end
end
