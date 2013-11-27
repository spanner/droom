# This migration comes from droom (originally 20130208035113)
class AccessTokenSecret < ActiveRecord::Migration
  def change
    add_column :droom_dropbox_tokens, :access_token_secret, :string
  end
end
