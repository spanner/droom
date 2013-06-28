# Taggings are the many to many links that associated tags with people and other things. There isn't much to see here.

module Droom
  class Tagging < ActiveRecord::Base
    belongs_to :tag
    belongs_to :taggee, :polymorphic => true
  
    # The tagging interface allows the creation of new tags on save but in normal use this would never be hit:
    # the ajax-based tag-adder creates tags in the background so the form needs only the nested tagging fields.
    #
    accepts_nested_attributes_for :tag, :reject_if => :all_blank
  end
end