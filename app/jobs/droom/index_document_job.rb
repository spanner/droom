require 'droom'

module Droom
  class IndexDocumentJob < ActiveJob::Base

    def perform(id, timestamp)
      if doc = Droom::Document.find(id)
        unless doc.indexed_at && doc.indexed_at.to_i > timestamp
          doc.update_index!
        end
      end
    end

  end
end