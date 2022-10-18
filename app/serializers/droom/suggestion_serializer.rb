require "jsonapi/serializer"

module Droom
  class SuggestionSerializer
    include JSONAPI::Serializer

    attribute(:type) { |object| object['type'].sub('droom/', '') }
    attribute(:prompt) { |object| object['name'] }
    attribute(:value) { |object| object['name'] }
    attribute(:id) { |object| object['id'] }

  end
end