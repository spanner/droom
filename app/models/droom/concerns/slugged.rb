module Droom::Concerns::Slugged
  extend ActiveSupport::Concern

  def slug_from_title
    ensure_presence_of_unique(:slug, title.parameterize)
  end

  def slug_from_name
    ensure_presence_of_unique(:slug, name.parameterize)
  end

  def slug_from_name_and_year
    ensure_presence_of_unique(:slug, "#{year} #{name}".parameterize)
  end

  def ensure_presence_of_unique(column, base, skope=self.class.all)
    unless self.send "#{column}?".to_sym
      slug = base.presence || self.class.to_s.underscore
      addendum = 0
      while skope.find_by(slug: slug)
        addendum += 1
        slug = "#{base}_#{addendum}"
      end
      self.send :"#{column}=", slug
    end
  end

end