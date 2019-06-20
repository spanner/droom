class LastRequestAt < ActiveRecord::Migration[5.2]
  def change
    add_column :droom_users, :last_request_at, :datetime
  end
end
