class Mailchimp < ActiveRecord::Migration[5.1]
  def change
    # NB. mailchimp subscription is controlled by a the `email.mailchimp?` user preference
    add_column :droom_users, :mailchimp_email, :string
    add_column :droom_users, :mailchimp_rating, :integer
    add_column :droom_users, :mailchimp_updated_at, :datetime
  end
end
