class PageSubtitle < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_pages, :subtitle, :text
    add_column :droom_pages, :published_subtitle, :text
  end
end
