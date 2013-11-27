class Honours < ActiveRecord::Migration
  def change
    add_column :droom_users, :honours, :string
  end
end
