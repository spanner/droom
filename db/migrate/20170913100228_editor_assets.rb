class EditorAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :droom_images, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.attachment :file
      t.integer :user_id
      t.string :attachee_type
      t.integer :attachee_id
      t.text :caption
      t.timestamps
    end
    create_index :droom_images, :user_id
    create_index :droom_images, [:attachee_type, :attachee_id]

    create_table :droom_videos, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.attachment :file
      t.string :youtube_id
      t.integer :user_id
      t.string :attachee_type
      t.integer :attachee_id
      t.text :caption
      t.timestamps
    end
    create_index :droom_videos, :user_id
    create_index :droom_videos, [:attachee_type, :attachee_id]
  end

  create_table :droom_pages, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
    t.text :title
    t.string :slug
    t.text :content
    t.integer :image_id
    t.integer :user_id
    t.boolean :public
    t.timestamps
  end
  create_index :droom_pages, :user_id

end
