class Droom::PageSerializer < ActiveModel::Serializer
  attributes :id,
             :slug,
             :title,
             :subtitle,
             :content,
             :image_url,
             :thumbnail_url


  def title
    object.published_title
  end

  def subtitle
    object.published_subtitle
  end

  def content
    object.render_published
  end

  def image_url
    object.published_image.url(:hero) if object.published_image
  end

  def thumbnail_url
    object.published_image.url(:icon) if object.published_image
  end

end
