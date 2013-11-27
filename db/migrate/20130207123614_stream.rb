class Stream < ActiveRecord::Migration
  def change
    create_table :droom_scraps do |t|
      t.string :name
      t.text :body
      t.attachment :image
      t.integer :image_offset_top
      t.integer :image_offset_left
      t.integer :image_scale_width
      t.integer :image_scale_height
      t.integer :created_by_id
      t.string :scraptype
      t.string :note
      t.timestamps
    end
  end
end
