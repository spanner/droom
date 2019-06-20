class JoinableOrganisation < ActiveRecord::Migration[5.2]
  def change
    add_column :droom_organisations, :joinable, :boolean, default: false
    add_column :droom_organisations, :email_domain, :string
    add_index :droom_organisations, :email_domain
  end
end
