module Droom
  class Page < ApplicationRecord
    attr_accessor :publish_now, :publishing
    after_save :publish_if_publishing

    scope :published, -> {
      where.not(published_at: nil)
    }

    def publish!
      unless publishing?
        update_attributes({
          published_title: title,
          published_image_id: image_id,
          published_content: content,
          published_at: Time.now
        })
      end
    end

    def published?
      published_at?
    end

    def publish_now?
      !!publish_now
    end

    def publishing?
      !!publishing
    end

    protected

    def publish_if_publishing
      publish! if publish_now?
    end
  end
end
