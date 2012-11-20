class Tags < ActiveRecord::Migration
  def change
    create_table :droom_tags do |t|
      t.column :name, :string
      t.column :parent_id, :integer
      t.column :created_by_id, :integer
      t.timestamps
    end
    
    create_table :droom_taggings do |t|
      t.column :tag_id, :integer
      t.column :taggee_id, :integer
      t.column :taggee_type, :string
      t.column :created_by_id, :integer
      t.timestamps
    end
  end
end
