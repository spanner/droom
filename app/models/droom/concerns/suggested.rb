# Historically the suggestion method was overloaded to do a lot of different work through the same interface,
# including a quick search box, many type-ahead finders and some association-creating ui elements.
# This is an attempt to modernise that function and keep it under control while migrating to a saner set of distinct functions.
#
module Droom::Concerns::Suggested
  extend ActiveSupport::Concern

  included do
    Droom.config.add_suggestible_class(self)
  end

  class_methods do
    def serialize_suggestion(search_result)
      resource = suggestion_serializer_class.new(search_result, is_collection: false).serializable_hash
      resource.as_json
    end

    def suggestion_serializer_class
      Droom::SuggestionSerializer
    end
  end
end