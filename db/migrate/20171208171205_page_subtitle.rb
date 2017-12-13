class PageSubtitle < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_pages, :subtitle, :text
  end
end
