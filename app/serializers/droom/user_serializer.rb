require 'active_model_serializers'

class Droom::UserSerializer < ActiveModel::Serializer
  attributes :uid, 
             :authentication_token, 
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :colloquial_name,
             :honours,
             :email,
             :phone,
             :mobile,
             :country_code,
             :images,
             :confirmed,
             :permission_codes,
             :person_uid,
             :unconfirmed_email,
             :password_set

  def confirmed
    object.confirmed?
  end
  
  def password_set
    object.password_set?
  end

  def images
    if object.image?
      {
        icon: object.image.url(:icon),
        thumbnail: object.image.url(:thumbnail),
        standard: object.image.url(:standard)
      }
    else
      {
        icon: "",
        thumbnail: "",
        standard: ""
      }
    end
  end

end
