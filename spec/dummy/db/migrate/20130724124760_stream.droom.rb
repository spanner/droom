# This migration comes from droom (originally 20130207123614)
class Stream < ActiveRecord::Migration
  def change
    create_table :droom_scraps do |t|
      t.string :name
      t.text :body
      t.attachment :image
      t.integer :created_by_id
      t.string :scraptype
      t.string :note
      t.timestamps
    end
  end
end
