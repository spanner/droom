class Enquiries < ActiveRecord::Migration
  def change
    create_table :droom_enquiries do |t|
      t.string :name
      t.string :email
      t.text :message
      t.boolean :closed, default: false
      t.timestamps
    end

    add_index :droom_enquries, :closed
  end
end
