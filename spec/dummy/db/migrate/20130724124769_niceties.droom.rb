# This migration comes from droom (originally 20130305151936)
class Niceties < ActiveRecord::Migration
  def change
    add_column :droom_invitations, :response, :integer, :default => 1
    add_column :droom_groups, :privileged, :boolean, :default => false
    add_column :droom_people, :privileged, :boolean, :default => false
  end
end
