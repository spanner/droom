class ImageWeighting < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_pages, :main_image_weighting, :string
    add_column :droom_pages, :published_image_weighting, :string
  end
end
