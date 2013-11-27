class Permissions < ActiveRecord::Migration
  
  def change
    create_table :droom_services do |t|
      t.string :name
      t.string :slug
      t.string :url
      t.text :description
    end
    
    create_table :droom_permissions do |t|
      t.integer :service_id
      t.string  :name
      t.string :slug
      t.text :description
      t.integer :position
      t.timestamps
    end

    create_table :droom_group_permissions do |t|
      t.integer :group_id
      t.integer :permission_id
      t.timestamps
    end

    create_table :droom_user_permissions do |t|
      t.integer :user_id
      t.integer :group_permission_id
      t.integer :permission_id
      t.timestamps
    end

  end
end
