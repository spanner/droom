module Droom
  class Tagging < ApplicationRecord
    belongs_to :tag
    belongs_to :taggee, :polymorphic => true
  end
end