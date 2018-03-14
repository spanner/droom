class OrgAdmin < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_users, :organisation_admin, :boolean, default: false, after: :organisation_id
  end
end
