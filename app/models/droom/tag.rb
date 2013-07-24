# Tags are simple one-word descriptors. There is no hierarchy or other structure among them.
# They are strictly catalogue data, used to locate people but not treated as part of the user record.

module Droom
  class Tag < ActiveRecord::Base
    # They are attached to people and other things through many-to-many taggings.
    #
    has_many :taggings
    has_many :taggees, :through => :taggings
    before_save :downcase
    
    ## Suggestions
    #
    # There is a tag-suggesting mechanism in the front end to encourage tag reuse and consistency.
    # It rests on this simple scope, which returns all tags matching a given string fragment.
    #
    scope :matching, -> fragment {
      fragment = "%#{fragment}%"
      where('tags.name like ?', fragment)
    }
  
    # The public-facing search engine is faceted and relies on a similar but broader suggestion mechanism
    # that offers both tags and institutions. In that situation we only want to display tags that will give
    # give results, so we limit the suggestions to only those tags that have been applied to a user.
    #
    scope :in_use, -> {
      joins("INNER JOIN taggings ON taggings.tag_id = tags.id")
      .group('tags.id')
      .having('count(taggings.tag_id) > 0')
    }

    # This returns a list of all the tags attached to any of a given set of objects.
    # In future it will support cloud-weighting. 
    #
    scope :attached_to_any_of, -> these {
      these = [these].flatten
      type = these.first.class.to_s
      placeholders = these.map{"?"}.join(',')
      select("droom_tags.*, count(droom_taggings.id) as use_count")
        .joins("INNER JOIN droom_taggings ON droom_taggings.tag_id = droom_tags.id")
        .where(["droom_taggings.taggee_type = ? and droom_taggings.taggee_id IN (#{placeholders})", *these.map(&:id).unshift(type)])
        .group('droom_tags.id')
    }

    # Suggestions are returned in a minimal format and need only contain name and (for the public search
    # where there are more possibilities) the type of suggestion.
    #
    def as_json(options={})
      {
        :id => id,
        :name => name,
        :type => 'tag'
      }
    end

    ## Keyword lists
    #
    # Sometimes we want the interface to present a simple comma-separated list.
    # These methods help to move to and from that form.
    #
    def self.from_list(list=[], or_create=true)
      list = list.split(/[,;]\s*/) if String === list
      list.uniq.map{|t| self.for(t, or_create) }.compact if list && list.any?
    end

    # Renders a set of tags as a comma-separated list.
    #
    def self.to_list(tags=[])
      tags.uniq.map(&:name).join(', ')
    end

    # Finds or creates a tag with the supplied title
    #
    def self.for(name, or_create=true)
      if or_create
        find_or_create_by_name(name)
      else
        find_by_name(name)
      end
    end


    ## Clouds
    #
    # The administrative interface offers a big tag cloud and drag and drop tag-merging. Tag size in the
    # cloud is based on a usage count that is retrieved here in a join with the taggings table. The cloud
    # display logic can be found in the [application_helper](../controllers/application_helper.html).
    #
    attr_accessor :cloud_size
    scope :with_usage_count, -> limit {
      select("tags.*, count(tt.id) AS weight").joins("INNER JOIN taggings as tt ON tt.tag_id = tags.id").group("tt.tag_id").order("weight DESC").limit(limit)
    }

    # *self.for_cloud* uses that scope to return a list of the most popular tags, weighted for display as a tag cloud
    # and re-sorted into alphabetical order (since to select the most popular we originally had to sort by weighting).
    #
    def self.for_cloud(limit=100)
      with_usage_count(limit).sort_by(&:name)
    end

    # This is here just to make tag interpolation a bit more readable.
    #
    def to_s
      name
    end
  
    ## Admin
    # 
    def assimilate(tag)
      self.taggees << tag.taggees
      tag.destroy
    end

  protected
  
    def downcase
      self.name = self.name.downcase
    end

  end
end