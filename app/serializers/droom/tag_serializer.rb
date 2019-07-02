class Droom::TagSerializer < ActiveModel::Serializer
  attributes :name, :synonyms

  def name
    object[:name]
  end

  def synonyms
    object[:synonyms]
  end
end
