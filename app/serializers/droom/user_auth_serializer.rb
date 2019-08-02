class Droom::UserAuthSerializer < ActiveModel::Serializer
  attributes :uid,
             :unique_session_id,
             :status,
             :name,
             :title,
             :given_name,
             :family_name,
             :chinese_name,
             :honours,
             :email,
             :phone,
             :mobile,
             :address,
             :confirmed,
             :permission_codes,
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

end
