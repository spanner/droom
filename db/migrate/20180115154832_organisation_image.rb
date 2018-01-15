class OrganisationImage < ActiveRecord::Migration[5.1]
  def change

    add_attachment :droom_organisations, :image

  end
end
