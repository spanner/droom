class ImageSerializer < ActiveModel::Serializer
  attributes :id,
             :file,
             :caption,
             :file_name,
             :remote_url,
             :file_size,
             :width,
             :height,
             :file_type,
             :file_updated_at,
             :urls
 
  def file_name
    object.file_file_name
  end

  def file_type
    object.file_content_type
  end

  def file_size
    object.file_file_size
  end
 
  def urls
    if object.file?
      {
        icon: object.file_url(:icon),
        half: object.file_url(:half),
        full: object.file_url(:full),
        hero: object.file_url(:hero)
      }
    else
      {
        icon: "",
        half: "",
        full: "",
        hero: ""
      }
    end
  end
  
end
