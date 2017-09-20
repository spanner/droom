class MainImages < ActiveRecord::Migration[5.1]
  def change
    rename_column :droom_pages, :image_id, :main_image_id
  end
end
