class Droom::UserSerializer < ActiveModel::Serializer
  attributes :id, 
             :uid, 
             :authentication_token, 
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :honours,
             :email,
             :phone,
             :thumbnail,
             :icon,
             :confirmed,
             :permission_codes,
             :person_uid

  def confirmed
    object.confirmed?
  end

end
