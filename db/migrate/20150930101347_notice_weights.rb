class NoticeWeights < ActiveRecord::Migration
  def change
    add_column :droom_scraps, :size, :integer, default: 1
  end
end
