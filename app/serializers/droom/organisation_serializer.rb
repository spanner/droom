require 'active_model_serializers'

class Droom::OrganisationSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :chinese_name,
             :description,
             :phone,
             :address,
             :owner_id,
             :organisation_type_id,
             :url,
             :facebook_page,
             :twitter_id,
             :instagram_id,
             :weibo_id,
             :logo_url

end
