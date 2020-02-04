module Droom
  class ChangesChannel < Channel
    def subscribed
      stream_from "changes"
    end

    def unsubscribed
      # No cleanup
    end

  end
end