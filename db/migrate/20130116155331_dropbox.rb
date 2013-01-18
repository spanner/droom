class Dropbox < ActiveRecord::Migration
  def change
    create_table :droom_dropbox_tokens do |t|
      t.column :created_by_id, :integer
      t.column :access_token, :string
      t.timestamps
    end
  end
end
