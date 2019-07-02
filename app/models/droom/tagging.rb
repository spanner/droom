module Droom
  class Tagging < Droom::DroomRecord
    belongs_to :tag
    belongs_to :taggee, :polymorphic => true
  end
end