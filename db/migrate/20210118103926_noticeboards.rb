class Noticeboards < ActiveRecord::Migration[6.1]
  def change

    create_table :droom_noticeboards, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :public, default: false
      t.timestamps
    end

    add_column :droom_scraps, :noticeboard_id, :integer
  end
end
