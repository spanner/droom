class MembershipsExpire < ActiveRecord::Migration
  def change
    add_column :droom_memberships, :expires, :datetime
  end
end
