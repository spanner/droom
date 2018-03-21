class ExternalOrganisation < ActiveRecord::Migration[5.1]
  def change
    add_column :droom_organisations, :external, :boolean, default: true
    add_index :droom_organisations, :external
    add_column :droom_users, :external, :boolean, default: true
    add_index :droom_users, :external
  end
end
