# Taggings are the many to many links that associated tags with people and other things. There isn't much to see here.

module Droom
  class Tagging < ApplicationRecord
    belongs_to :tag
    belongs_to :taggee, :polymorphic => true
  end
end