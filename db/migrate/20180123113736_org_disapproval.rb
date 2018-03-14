class OrgDisapproval < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_organisations, :disapproved_at, :datetime
    add_column :droom_organisations, :disapproved_by_id, :integer
  end
end
