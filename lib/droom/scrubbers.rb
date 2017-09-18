module Droom
  class Scrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w{div figure img figcaption p ul ol li blockquote em i strong b a iframe}
      self.attributes = %w{href rel src class allowfullscreen frameborder}
    end
  end
end