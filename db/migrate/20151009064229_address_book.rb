class AddressBook < ActiveRecord::Migration
  def change
    create_table :droom_address_types do |t|
      t.string :name
      t.string :relevance
      t.timestamps
    end
    add_index :droom_address_types, :relevance

    create_table :droom_emails do |t|
      t.integer :user_id
      t.integer :address_type_id
      t.string :email
      t.boolean :default, default: false
      t.timestamps
    end
    add_index :droom_emails, :user_id
    add_index :droom_emails, :email
    add_index :droom_emails, :default

    create_table :droom_phones do |t|
      t.integer :user_id
      t.integer :address_type_id
      t.string :phone
      t.boolean :default, default: false
      t.timestamps
    end
    add_index :droom_phones, :user_id
    add_index :droom_phones, :phone
    add_index :droom_phones, :default

    create_table :droom_addresses do |t|
      t.integer :user_id
      t.integer :address_type_id
      t.text :address
      t.string :line_1
      t.string :line_2
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :country_code
      t.boolean :default, default: false
      t.timestamps
    end
    add_index :droom_addresses, :user_id
    add_index :droom_addresses, :default

  end
end
