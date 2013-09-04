class InternationalNames < ActiveRecord::Migration
  def change
    rename_column :droom_users, :name, :family_name
    rename_column :droom_users, :forename, :given_name
    add_column :droom_users, :chinese_name, :string
    add_column :droom_users, :gender, :string, limit: 1
    
    Droom::User.reset_column_information
    Droom::User.all.each do |u|
      unless u.given_name?
        names = u.family_name.split(/\s+/)
        surname = names.pop
        u.update_attributes(family_name: surname, given_name: names.join(' '))
      end
    end
  end
end
