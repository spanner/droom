class ShyPeople < ActiveRecord::Migration
  def change
    rename_column :droom_people, :private, :shy
    rename_column :droom_documents, :private, :secret
  end
end
