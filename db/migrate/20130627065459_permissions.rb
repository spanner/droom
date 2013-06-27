class Permissions < ActiveRecord::Migration
  
  def change
    create_table :droom_resources do |t|
      t.string :name
      t.string :url
    end
    
    create_table :droom_permissions do |t|
      t.integer :resource_id
      t.string  :name
      t.timestamps
    end

    create_table :droom_group_permissions do |t|
      t.integer :group_id
      t.integer :permission_id
      t.timestamps
    end

  end
end
