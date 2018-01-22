class OrgApproval < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_organisations, :approved_at, :datetime
    add_column :droom_organisations, :approved_by_id, :integer
  end
end
