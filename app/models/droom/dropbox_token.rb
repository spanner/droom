module Droom
  class DropboxToken < ActiveRecord::Base
    belongs_to :created_by, :class_name => "Droom::User"
    after_create :delete_previous
    
    scope :by_date, order("created_at DESC")
    scope :other_than, lambda { |token| where "id <> ?", token.id }
    
    def dropbox_session
      unless @dbsession
        @dbsession = DropboxSession.new(Droom.dropbox_app_key, Droom.dropbox_app_secret)
        @dbsession.set_access_token(access_token, access_token_secret)
      end
      @dbsession
    end
    
    def dropbox_client
      @dbclient ||= DropboxClient.new(dropbox_session)
    end
    
  protected

    def delete_previous
      self.created_by.dropbox_tokens.other_than(self).destroy_all
    end

  end
end