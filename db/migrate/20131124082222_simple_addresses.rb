class SimpleAddresses < ActiveRecord::Migration
  def change
    add_column :droom_venues, :address, :text
    add_column :droom_venues, :slug, :string
    add_column :droom_users, :address, :text
    add_column :droom_venues, :country_code, :string
    add_column :droom_users, :country_code, :string
    
    remove_column :droom_users, :post_line1
    remove_column :droom_users, :post_line2
    remove_column :droom_users, :post_city
    remove_column :droom_users, :post_region
    remove_column :droom_users, :post_country

  end
end
