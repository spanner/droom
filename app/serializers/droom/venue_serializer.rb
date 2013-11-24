class Droom::VenueSerializer < ActiveModel::Serializer
  attributes :id, :name, :definite_name, :address, :post_code, :country_code, :lat, :lng
end
