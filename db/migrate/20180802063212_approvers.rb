class Approvers < ActiveRecord::Migration[5.2]
  def change
    add_column :droom_users, :gatekeeper, :boolean, default: false
    add_index :droom_users, :gatekeeper
  end
end
