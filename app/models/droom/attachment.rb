module Droom
  class Attachment < ActiveRecord::Base
    belongs_to :document
    belongs_to :attachee, :polymorphic => true
    belongs_to :created_by, :class_name => "User"
  end
end