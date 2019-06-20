class EditorAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :droom_images, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.attachment :file
      t.integer :user_id
      t.integer :organisation_id
      t.string :remote_url
      t.text :caption
      t.integer :width
      t.integer :height
      t.timestamps
    end
    add_index :droom_images, :user_id

    create_table :droom_videos, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.attachment :file
      t.integer :user_id
      t.integer :organisation_id
      t.string :remote_url
      t.text :title
      t.text :caption
      t.integer :file_meta
      t.integer :height
      t.integer :width
      t.integer :duration
      t.string :provider
      t.string :thumbnail_large
      t.string :thumbnail_medium
      t.string :thumbnail_small
      t.text :embed_code
      t.timestamps
    end
    add_index :droom_videos, :user_id

    create_table :droom_pages, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :slug
      t.string :title
      t.text :published_title
      t.text :content
      t.text :published_content
      t.integer :image_id
      t.integer :published_image_id
      t.integer :user_id
      t.boolean :public
      t.timestamps
      t.datetime :published_at
    end
    add_index :droom_pages, :user_id
    add_index :droom_pages, :slug
  end

end
