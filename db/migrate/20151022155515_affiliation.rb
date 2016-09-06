class Affiliation < ActiveRecord::Migration
  def change
    add_column :droom_users, :affiliation, :string
  end
end
