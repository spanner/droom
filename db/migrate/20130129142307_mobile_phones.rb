class MobilePhones < ActiveRecord::Migration
  def change
    add_column :droom_people, :mobile, :string
    add_column :droom_people, :dob, :datetime
    add_column :droom_people, :female, :boolean
    add_column :droom_people, :joined_at, :datetime
  end
end
