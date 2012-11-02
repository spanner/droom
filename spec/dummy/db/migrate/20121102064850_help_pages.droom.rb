# This migration comes from droom (originally 20121012154558)
class HelpPages < ActiveRecord::Migration
  def change
    create_table :droom_pages do |t|
      t.column :title, :string
      t.column :slug, :string
      t.column :summary, :text
      t.column :body, :text
      t.column :rendered_body, :text
      t.column :video_id, :string
      t.timestamps
    end
  end
end
