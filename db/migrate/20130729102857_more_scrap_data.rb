class MoreScrapData < ActiveRecord::Migration
  def change
    add_column :droom_scraps, :youtube_id, :string
    add_column :droom_scraps, :url, :string
    
    Droom::Scrap.reset_column_information
    Droom::Scrap.videos.each do |scrap|
      scrap.update_column(:youtube_id, scrap.body)
      scrap.update_column(:body, "")
    end
  end
end
