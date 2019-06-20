require 'active_model_serializers'

class Droom::UserSerializer < ActiveModel::Serializer
  attributes :uid,
             :authentication_token,
             :status,
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :name,
             :honours,
             :affiliation,
             :email,
             :phone,
             :mobile,
             :address,
             :correspondence_address,
             :country_code,
             :images,
             :confirmed,
             :permission_codes,
             :organisation_id,
             :organisation_data,
             :password_set

  def name
    object.colloquial_name
  end

  def confirmed
    object.confirmed?
  end

  def password_set
    object.password_set?
  end

  def images
    if object.image?
      {
        icon: object.image_url(:icon),
        thumbnail: object.image_url(:thumbnail),
        standard: object.image_url(:standard)
      }
    else
      {
        icon: "",
        thumbnail: "",
        standard: ""
      }
    end
  end

  def organisation_data
    Droom::OrganisationSerializer.new(object.organisation).as_json if object.organisation
  end

end
