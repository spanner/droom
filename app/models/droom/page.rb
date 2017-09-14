module Droom
  class Page < ApplicationRecord

    def publish!
      update_attributes {
        published_title: title,
        published_image_id: image_id,
        published_content: content,
        published_at: Time.now
      }
    end

  end
end
