class PresenceUnlessRecurrenceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :blank) if attribute.blank? && !master_id?
  end
end

class UniquenessAmongSiblingsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :taken) if record.siblings.send(:"find_by_#{attribute}", value)
  end
end
