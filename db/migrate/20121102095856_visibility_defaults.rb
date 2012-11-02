class VisibilityDefaults < ActiveRecord::Migration
  def change
    change_column_default :droom_people, :shy, false
    change_column_default :droom_people, :public, false
    change_column_default :droom_documents, :secret, false
    change_column_default :droom_documents, :public, false
  end
end
