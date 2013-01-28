module Droom
  class DropboxToken < ActiveRecord::Base
    attr_accessible :access_token, :created_by
    belongs_to :created_by, :class_name => "Droom::User"
    after_create :delete_previous
    
    scope :by_date, order("created_at DESC")
    scope :other_than, lambda { |token| where "id <> ?", token.id }
    
  protected

    def delete_previous
      self.created_by.dropbox_tokens.other_than(self).destroy_all
    end

  end
end