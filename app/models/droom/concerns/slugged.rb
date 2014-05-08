module Droom::Concerns::Slugged
  extend ActiveSupport::Concern
  
  def slug_from_name
    ensure_presence_of_unique(:slug, name.parameterize)
  end

  def slug_from_name_and_year
    ensure_presence_of_unique(:slug, "#{year} #{name}".parameterize)
  end

  def ensure_presence_of_unique(column, base, skope=self.class.all)
    unless self.send "#{column}?".to_sym
      value = base
      addendum = 0
      value = "#{base}_#{addendum+=1}" while skope.find_by(column => value)
      self.send :"#{column}=", value
    end
  end

end