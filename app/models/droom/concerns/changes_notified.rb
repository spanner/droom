module Droom::Concerns::ChangesNotified
  extend ActiveSupport::Concern

  included do
    after_create :notify_of_creation
    after_update :notify_of_update
    after_destroy :notify_of_destruction
  end

  def timestamp
    (try(:updated_at) || try(:created_at) || Time.now).to_f
  end

  def notify_of_change(event, additional_data={})
    if Droom.config.enable_pubsub?
      time = event == 'destroyed' ? Time.now.to_i : timestamp
      change_data = {
        event: event,
        timestamp: time,
        object_class: self.class.to_s.underscore,
        object_id: id,
      }
      Droom::ChangesChannel.broadcast_to 'changes', change_data.merge(additional_data)
    end
  end

  def notify_of_creation(additional_data={})
    notify_of_change "created", additional_data
  end

  def notify_of_update(additional_data={})
    notify_of_change "updated", additional_data
  end

  def notify_of_destruction(additional_data={})
    notify_of_change "destroyed", additional_data
  end

end