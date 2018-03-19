class PageIntro < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_pages, :intro, :text
    add_column :droom_pages, :published_intro, :text
  end
end
