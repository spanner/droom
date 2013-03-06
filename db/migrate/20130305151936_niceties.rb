class Niceties < ActiveRecord::Migration
  def change
    add_column :droom_invitations, :attending, :integer, :default => 0
    add_column :droom_groups, :privileged, :boolean, :default => false
    add_column :droom_people, :privileged, :boolean, :default => false
  end
end
