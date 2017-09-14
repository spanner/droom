require 'active_model_serializers'

class Droom::VideoSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :file_name,
             :remote_url,
             :provider,
             :file_type,
             :file_size,
             :width,
             :height,
             :duration,
             :file_updated_at,
             :embed_code,
             :url,
             :thumb_url,
             :half_url,
             :full_url

  def title
    [object.provider, object.title.presence || object.file_file_name].compact.join(': ')
  end

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
    if object.file?
      object.file_url(:original)
    else
      object.remote_url
    end
  end

  def thumb_url
    if object.file?
      object.file_url(:thumb)
    else
      object.thumbnail_small
    end
  end

  def half_url
    if object.file?
      object.file_url(:half)
    else
      object.thumbnail_medium
    end
  end

  def full_url
    if object.file?
      object.file_url(:full)
    else
      object.thumbnail_large
    end
  end

end
