class PresenceUnlessRecurrenceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :blank) if attribute.blank? && !master_id?
  end
end

