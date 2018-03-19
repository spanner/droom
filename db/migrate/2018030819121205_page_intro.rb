class PageIntro < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_pages, :intro, :text
    add_column :droom_pages, :published_intro, :text
    add_column :droom_pages, :main_image_caption, :text
    add_column :droom_pages, :published_image_caption, :text
  end
end
