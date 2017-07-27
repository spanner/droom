class UpdateOrganisations < ActiveRecord::Migration[5.0]
  def change
    change_table :droom_organisations do |t|
      t.string :chinese_name
      t.string :phone
      t.text :address
    end
  end
end
