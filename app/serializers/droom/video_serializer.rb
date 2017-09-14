class VideoSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :caption,
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
             :thumb_url,
             :half_url,
             :full_url,
             :url

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
    object.file_url(:original)
  end

  def urls
    if object.file?
      {
        icon: object.file_url(:icon),
        thumb: object.file_url(:thumb),
        full: object.file_url(:full)
      }
    else
      {
        icon: thumbnail_small.presence || "",
        half: object.thumbnail_medium.presence || "",
        full: object.thumbnail_large.presence || ""
      }
    end
  end

end
