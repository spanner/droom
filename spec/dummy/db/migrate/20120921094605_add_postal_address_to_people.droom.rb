# This migration comes from droom (originally 20120918121352)
class AddPostalAddressToPeople < ActiveRecord::Migration
  def change
    add_column :droom_people, :post_line1, :string
    add_column :droom_people, :post_line2, :string
    add_column :droom_people, :post_city, :string
    add_column :droom_people, :post_region, :string
    add_column :droom_people, :post_country, :string
    add_column :droom_people, :post_code, :string
  end
end
