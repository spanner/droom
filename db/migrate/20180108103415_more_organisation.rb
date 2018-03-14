class MoreOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_attachment :droom_organisations, :logo
    add_column :droom_organisations, :facebook_page, :string
    add_column :droom_organisations, :twitter_id, :string
    add_column :droom_organisations, :instagram_id, :string
    add_column :droom_organisations, :weibo_id, :string
  end
end
