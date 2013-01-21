module Droom
  module Taggability
  
    def self.included(base)
      base.extend TaggableClassMethods
    end

    module TaggableClassMethods
      def has_tags?
        false
      end
      
      def has_tags
        return if has_tags?
        has_many :taggings, :as => :taggee, :class_name => "Droom::Tagging"
        has_many :tags, :through => :taggings, :class_name => "Droom::Tag"

        class_eval {
          extend Droom::Taggability::TaggedClassMethods
          include Droom::Taggability::TaggedInstanceMethods
        }
      end
    end

    module TaggedClassMethods
      def has_tags?
        true
      end
    end
  
    module TaggedInstanceMethods
      def add_tag(word=nil)
        self.tags << Tag.for(word) if word && !word.blank?
      end

      def remove_tag(word=nil)
        tag = Tag.find_by_title(word) if word && !word.blank?
        self.tags.delete(tag) if tag
      end
    
      def keywords
        self.tags.map {|t| t.name}.join(', ')
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
  end

end