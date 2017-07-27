class OrganisationType < ActiveRecord::Migration[5.0]
  def change
    create_table :droom_organisation_types do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.timestamps
    end
    
    add_column :droom_organisations, :organisation_type_id, :integer
    add_index :droom_organisations, :organisation_type_id
    
  end
end
