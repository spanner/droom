require 'active_model_serializers'

class Droom::TagSerializer < ActiveModel::Serializer
  attributes :name, :synonyms
end
