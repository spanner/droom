# This migration comes from droom (originally 20121102095856)
class VisibilityDefaults < ActiveRecord::Migration
  def change
    rename_column :droom_documents, :private, :secret
    change_column_default :droom_people, :shy, false
    change_column_default :droom_people, :public, false
    change_column_default :droom_documents, :secret, false
    change_column_default :droom_documents, :public, false
  end
end
