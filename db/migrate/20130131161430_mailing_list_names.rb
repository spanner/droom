class MailingListNames < ActiveRecord::Migration
  def change
    add_column :droom_groups, :mailing_list_name, :string
  end
end
