module Droom
  class MailchimpSubscriptionJob < ApplicationJob
    queue_as :default

    def perform(id, timestamp)
      if user = Droom::User.find(id)
        user.upsert_in_mailchimp_list unless user.mailchimp_updated_at? && user.mailchimp_updated_at.to_i > timestamp
      end
    end

  end
end