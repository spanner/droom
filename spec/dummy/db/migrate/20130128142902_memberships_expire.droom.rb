# This migration comes from droom (originally 20121220145827)
class MembershipsExpire < ActiveRecord::Migration
  def change
    add_column :droom_memberships, :expires, :datetime
  end
end
