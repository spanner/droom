module Droom
  class Help < ApplicationRecord

    belongs_to :main_image, class_name: "Droom::Image"

    scope :published, -> {
      where.not(published_at: nil)
    }

    def illustrated?
      !!main_image
    end

  end
end
