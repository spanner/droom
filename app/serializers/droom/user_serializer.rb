class Droom::UserSerializer < ActiveModel::Serializer
  attributes :id, :uid, :title, :given_name, :family_name, :chinese_name, :honours, :email, :permission_codes, :thumbnail
end
