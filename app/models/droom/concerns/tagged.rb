module Droom::Concerns::Tagged
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggee, class_name: "Droom::Tagging"
    has_many :tags, through: :taggings, class_name: "Droom::Tag"
  end

  def tag_list
    tags.map(&:name).uniq.join(",")
  end

  def tags_with_synonyms
    tags.includes(:tag_synonyms).map(&:with_synonyms).flatten.uniq
  end

  def tag_list=(tag_list)
    self.tags = tag_list.split(/,\s*/).map { |t| Tag.find_or_create(t) }
  end

  # To support ancient keywords= interface

  def keywords
    self.tags.pluck(:name).compact.uniq.join(', ')
  end

  def keywords_before_type_cast   # for form_helper
    keywords
  end

  def keywords=(somewords="")
    if somewords.blank?
      self.tags.clear
    else
      self.tags = Tag.from_list(somewords)
    end
  end



end