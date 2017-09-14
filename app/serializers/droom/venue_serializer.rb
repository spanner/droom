require 'active_model_serializers'

class Droom::VenueSerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :definite_name, :address, :post_code, :country_code, :lat, :lng
end
