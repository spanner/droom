# This migration comes from droom (originally 20130627073759)
class UserProperties < ActiveRecord::Migration
  def change
    add_column :droom_users, :uid, :string
    add_column :droom_users, :organisation_id, :integer
    add_column :droom_users, :phone, :string
    add_column :droom_users, :description, :text
    add_column :droom_users, :post_line1, :string
    add_column :droom_users, :post_line2, :string
    add_column :droom_users, :post_city, :string
    add_column :droom_users, :post_region, :string
    add_column :droom_users, :post_country, :string
    add_column :droom_users, :post_code, :string
    add_column :droom_users, :mobile, :string
    add_column :droom_users, :dob, :datetime
    add_column :droom_users, :private, :boolean
    add_column :droom_users, :public, :boolean
    add_column :droom_users, :female, :boolean
    add_attachment :droom_users, :image
    add_column :droom_users, :image_offset_top, :integer
    add_column :droom_users, :image_offset_left, :integer
    add_column :droom_users, :image_scale_width, :integer
    add_column :droom_users, :image_scale_height, :integer

    Droom::User.reset_column_information
    Droom::Person.all.each do |p|
      if u = Droom::User.find(p.user_id)
        u.update_attributes p.attributes.slice(*%w{organisation_id phone description description post_line1 post_line2 post_city post_region post_country post_code mobile image})
      end
    end

  end
end


