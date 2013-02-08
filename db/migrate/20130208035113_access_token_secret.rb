class AccessTokenSecret < ActiveRecord::Migration
  def change
    add_column :droom_dropbox_tokens, :access_token_secret, :string
  end
end
