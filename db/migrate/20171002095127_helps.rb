class Helps < ActiveRecord::Migration[5.1]
  def change
    create_table :droom_helps, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :title
      t.string :slug
      t.string :category
      t.integer :main_image_id
      t.text :content
      t.timestamps
    end
    add_index :droom_helps, [:category, :slug]
  end
end
