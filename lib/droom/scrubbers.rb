module Droom
  class Scrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w{p ul ol li blockquote em i strong b a}
      self.attributes = %w{href rel}
    end
  end
end