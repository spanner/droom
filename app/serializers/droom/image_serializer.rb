require 'active_model_serializers'

class Droom::ImageSerializer < ActiveModel::Serializer
  attributes :id,
             :file,
             :file_name,
             :remote_url,
             :file_size,
             :width,
             :height,
             :file_type,
             :file_updated_at,
             :url,
             :icon_url,
             :half_url,
             :full_url,
             :hero_url
 
  def file_name
    object.file_file_name
  end

  def file_type
    object.file_content_type
  end

  def file_size
    object.file_file_size
  end
 
  def url
    object.url(:original).presence || ""
  end

  def icon_url
    object.url(:icon).presence || ""
  end

  def half_url
    object.url(:half).presence || ""
  end

  def full_url
    object.url(:full).presence || ""
  end

  def hero_url
    object.url(:hero).presence || ""
  end

end
