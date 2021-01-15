module Droom::Concerns::Imaged
  extend ActiveSupport::Concern

  included do
    has_attached_file :image,
                      styles: {
                        icon: "32x32#",
                        thumb: ["128x96#", :png],
                        standard: ["640x480>", :jpg],
                        hero: ["1920x1080>", :jpg]
                      },
                      convert_options: {
                        icon: "-strip",
                        thumb: "-strip",
                        standard: "-quality 50 -strip",
                        hero: "-quality 25 -strip"
                      }
    validates_attachment :image, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }
  end

  ## Images
  #
  def image_url(style=:standard, decache=true)
    if image?
      url = image.url(style, decache)
      url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
    else
      ""
    end
  end

  def icon_url(decache=true)
    if image?
      url = image.url(:icon, decache)
      url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
    else
      ""
    end
  end

  def thumbnail_url(decache=true)
    if image?
      url = image.url(:thumbnail, decache)
      url.sub(/^\//, "#{Settings.protocol}://#{Settings.host}/")
    else
      ""
    end
  end

  # Images usually come to us as data: urls but can also be given as actual url or assigned directly as file.
  #
  def image_url=(address)
    if address.present?
      self.image = URI(address)
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.warn "Cannot read image url #{address} because: #{e}. Skipping."
  end

  # image_data should be a fully specified data: url in base64 with prefix. Paperclip knows what to do with it.
  #
  def image_data=(data_uri)
    if data_uri.present?
      self.image = data_uri
    end
  end

  # If image_data is given then the file name should be also supplied as `image_name`.
  # You normally want to call this method after image_url= or image_data=, eg by ordering
  # parameters in the controller.
  #
  def image_name=(name)
    self.image_file_name = name
  end

  def thumbnail
    image_url(:thumb)
  end

  def icon
    image_url(:icon)
  end

end