class PrivateEventTypes < ActiveRecord::Migration
  def change
    add_column :droom_event_types, :private, :boolean, default: false
    add_column :droom_event_types, :public, :boolean, default: false
  end
end
