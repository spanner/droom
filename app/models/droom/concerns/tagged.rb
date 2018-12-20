module Droom::Concerns::Tagged
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggee, class_name: "Droom::Tagging"
    has_many :tags, through: :taggings, class_name: "Droom::Tag"
  end

  class_methods do
    def tagged_like(thing, limit=nil, offset=nil)
      with_tags_like thing.tag_names, limit, offset
    end

    def with_tags_like(tags, limit=nil, offset=nil)
      matchers = tags.map { |tag_name| { term: { tags: tag_name } }}
      args = { body: {
        query: { bool: {should: matchers} },
        sort: "_score"
      }}
      # args[:size] = limit if limit
      # args[:from] = offset if offset
      projects = self.search args
      Rails.logger.warn "with_tags_like response: #{projects.response.inspect}"
      projects
    end
  end

  def tag_list
    tag_names.join(",")
  end

  def tag_names
    tags.map(&:name).uniq
  end

  def tags_with_synonyms
    tags.includes(:tag_synonyms).map(&:with_synonyms).flatten.uniq.join(' ')
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
      self.tags = Droom::Tag.from_list(somewords)
    end
  end

end