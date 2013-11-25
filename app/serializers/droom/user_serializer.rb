class Droom::UserSerializer < ActiveModel::Serializer
  attributes :id, :uid, :title, :name, :informal_name, :formal_name, :colloquial_name, :given_name, :family_name, :chinese_name, :honours, :email, :thumbnail
end
