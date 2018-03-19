require 'mustache'

module Droom
  class Page < ApplicationRecord
    include Droom::Concerns::Slugged
    include Droom::Concerns::Published

    before_validation :slug_from_title

  end
end
