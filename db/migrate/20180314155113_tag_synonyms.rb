class TagSynonyms < ActiveRecord::Migration[5.1]
  def change

    create_table :droom_tag_synonyms, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :tag_id
      t.string :synonym
      t.timestamps
    end
    add_index :droom_tag_synonyms, :tag_id

    create_table :droom_tag_types, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :name
      t.timestamps
    end
    add_column :droom_tags, :tag_type_id, :integer
    add_index :droom_tags, :tag_type_id
  end
end
