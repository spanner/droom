class IndexTimes < ActiveRecord::Migration
  def change
    add_column :droom_documents, :indexed_at, :datetime
    add_column :droom_users, :indexed_at, :datetime
    add_column :droom_events, :indexed_at, :datetime
  end
end
