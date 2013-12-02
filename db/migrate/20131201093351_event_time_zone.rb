class EventTimeZone < ActiveRecord::Migration
  def change
    add_column :droom_events, :timezone, :string
  end
end
