class LoginToken < ActiveRecord::Migration[6.1]
  def change
    add_column :droom_users, :login_token, :string
    add_column :droom_users, :login_token_created_at, :datetime
    add_index  :droom_users, [:uid, :login_token, :login_token_created_at]
  end
end
